import json
from typing import List, Dict, Any, AsyncGenerator
from openai import AsyncOpenAI

from mcp_client import MCPClient
from models import AgentResponse

import os
from datetime import datetime, timezone

class QueryLogger:
    def __init__(self, user_message: str, model_name: str):
        self.model_name = model_name
        self.query_log = {
            "model": model_name,
            "query": user_message,
            "start_time_stamp": datetime.now(timezone.utc).isoformat(),
            "loops": {},
            "end_time_stamp": None,
            "total_prompt_tokens": 0,
            "total_completion_tokens": 0,
            "total_tokens": 0,
            "total_cost_usd": 0.0
        }
    
    def log_loop(self, loop_name: str, step_name: str, usage):
        if not usage: return
        self.query_log["loops"][loop_name] = {
            "step": step_name,
            "prompt_tokens": usage.prompt_tokens,
            "completion_tokens": usage.completion_tokens,
            "total_tokens": usage.total_tokens
        }
        self.query_log["total_prompt_tokens"] += usage.prompt_tokens
        self.query_log["total_completion_tokens"] += usage.completion_tokens
        self.query_log["total_tokens"] += usage.total_tokens
        
    def save(self):
        self.query_log["end_time_stamp"] = datetime.now(timezone.utc).isoformat()
        
        # Calculate cost
        cost_file = os.path.join(os.path.dirname(__file__), "api_costs.json")
        try:
            with open(cost_file, "r", encoding="utf-8") as f:
                costs = json.load(f)
            model_costs = costs.get(self.model_name, costs.get("default", {"prompt_cost_per_1m": 0, "completion_cost_per_1m": 0}))
            
            prompt_cost = (self.query_log["total_prompt_tokens"] / 1000000.0) * model_costs["prompt_cost_per_1m"]
            comp_cost = (self.query_log["total_completion_tokens"] / 1000000.0) * model_costs["completion_cost_per_1m"]
            self.query_log["total_cost_usd"] = round(prompt_cost + comp_cost, 6)
        except Exception as e:
            print(f"Error calculating token cost: {e}")
            pass

        log_dir = "logs"
        os.makedirs(log_dir, exist_ok=True)
        today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        log_file_path = os.path.join(log_dir, f"log_{today_str}.json")
        
        log_data = {"date": today_str, "queries": []}
        if os.path.exists(log_file_path):
            try:
                with open(log_file_path, "r", encoding="utf-8") as f:
                    log_data = json.load(f)
            except Exception:
                pass
                
        log_data["queries"].append(self.query_log)
        
        with open(log_file_path, "w", encoding="utf-8") as f:
            json.dump(log_data, f, indent=2)

if os.environ.get("OLLAMA_MODEL"):
    client = AsyncOpenAI(
        api_key="ollama", # required but ignored by ollama
        base_url="http://localhost:11434/v1"
    )
    MODEL_NAME = os.environ.get("OLLAMA_MODEL")
elif os.environ.get("GEMINI_API_KEY"):
    client = AsyncOpenAI(
        api_key=os.environ.get("GEMINI_API_KEY"),
        base_url="https://generativelanguage.googleapis.com/v1beta/openai/"
    )
    MODEL_NAME = os.environ.get("MODEL_NAME") or "gemini-flash-lite-latest"
else:
    client = AsyncOpenAI()
    MODEL_NAME = os.environ.get("MODEL_NAME") or "gpt-4o"

SYSTEM_PROMPT = """You are a supply chain business intelligence assistant powered by Gilhari ORM.
Your goal is to answer queries by fetching data, calculating aggregations, or mutating records (create/update/delete) when explicitly requested.

--- 1. DATA READING STRATEGY ---
- MANDATORY SCHEMA DISCOVERY: You MUST use `getObjectModelSummary` FIRST on every new complex request to ensure you have complete clarity on the schema, exact fields, and class names before writing any queries.
- DECISION MAKING (RAW SQL vs ORMCP): After fetching the object model, YOU decide the most efficient path to get the data:
   * Use ORMCP tools (`query`, `getAggregate`, `direct_fetch_table`) for simple, single-table reads.
   * Use `execute_raw_sql` for complex reads involving JOINs, cross-table filtering, or GROUP BY aggregations.
- SQL CONVENTIONS: When writing raw SQL, remember that SQL Server table names are simply pluralized versions of the Gilhari class names (e.g. `Supplier` -> `Suppliers`, `PurchaseOrder` -> `PurchaseOrders`).
- AVOID DATA DUMPS: NEVER use `query` to fetch entire tables without filters/limits. Avoid hallucinating massive `IN (...)` clauses. If you need cross-table filtering, use `execute_raw_sql`.

--- 2. DATA MUTATION STRATEGY ---
- STRICT TOOL USAGE: `execute_raw_sql` is strictly READ-ONLY. You MUST use the designated ORMCP tools (`insert`, `update`, `delete`) for all data modifications.
- MULTI-HOP REASONING: If updating/deleting an entity based on a related entity's condition, find the relevant primary keys via a bridging table first, then execute the mutation on the exact target IDs. Do not hallucinate fields across unrelated classes.

--- 3. UI RESPONSE GENERATION ---
- DIRECT HYDRATION: If requested to show a data table, ALWAYS use `direct_fetch_table`.
- STOP CALLING TOOLS TO FINISH: Once you have fetched the required data (e.g. from `execute_raw_sql` or `getAggregate`), you MUST STOP calling tools! Simply output a conversational text message (e.g., "I have the data now.") without invoking any tools.
- Once you stop calling tools, the system will execute a final step where you will be provided with the JSON schemas for the Generative UI (e.g. `chart_view`, `metric_kpi_view`, `timeline_view`, etc.). DO NOT try to call these as tools during the data gathering phase! Just gather the data, then stop calling tools.
"""

async def process_chat_message(user_message: str, mcp_client: MCPClient) -> AsyncGenerator[str, None]:
    query_logger = QueryLogger(user_message, MODEL_NAME)
    
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": user_message}
    ]

    tools = await mcp_client.get_openai_tools()
    
    # Inject our custom Direct Data Hydration tool only if a table is requested
    if "table" in user_message.lower():
        tools.append({
            "type": "function",
            "function": {
                "name": "direct_fetch_table",
                "description": "Call this tool instead of 'query' when the user asks for a table of data. IMPORTANT: You MUST call 'getObjectModelSummary' first to get the correct fully-qualified 'class_name' and correct 'columns' before calling this tool!",
            "parameters": {
                "type": "object",
                "properties": {
                    "class_name": {"type": "string", "description": "The fully qualified Gilhari class name (e.g., com.supplychain.model.Supplier). ALWAYS include the com.supplychain.model. prefix!"},
                    "filter_clause": {"type": "string", "description": "Optional SQL WHERE clause boolean expression ONLY (e.g. deliveryStatus = 'Pending'). NEVER put 'ORDER BY' or 'LIMIT' here! Use the sort_column and limit parameters instead."},
                    "columns": {"type": "array", "items": {"type": "string"}, "description": "List of column names to display in the table"},
                    "sort_column": {"type": "string", "description": "Optional column name to sort the results by"},
                    "sort_order": {"type": "string", "description": "Optional sort direction, either 'ASC' or 'DESC'"},
                    "limit": {"type": "integer", "description": "Optional maximum number of rows to return"}
                },
                "required": ["class_name", "columns"]
            }
        }
    })
    
    tools.append({
        "type": "function",
        "function": {
            "name": "execute_raw_sql",
            "description": "Execute arbitrary READ-ONLY raw SQL queries directly against the database (supports JOINs, GROUP BYs, etc). IMPORTANT: Only use this for SELECT statements to fetch complex data efficiently. NEVER use this for INSERT, UPDATE, or DELETE. The database is 'supply_chain_db'.",
            "parameters": {
                "type": "object",
                "properties": {
                    "sql_query": {"type": "string", "description": "The exact SQL query to execute. E.g. 'SELECT TOP 5 s.companyName, SUM(poi.quantityOrdered) as totalVol FROM Suppliers s JOIN InventoryItems i ON s.supplierID = i.supplierID JOIN PurchaseOrderItems poi ON i.itemID = poi.itemID GROUP BY s.companyName ORDER BY totalVol DESC'"}
                },
                "required": ["sql_query"]
            }
        }
    })
    
    # Tool execution loop
    max_loops = 12
    for loop_count in range(max_loops):
        print(f"\n--- Agent Reasoning Loop {loop_count+1}/{max_loops} ---")
        response = await client.chat.completions.create(
            model=MODEL_NAME,
            messages=messages,
            tools=tools,
            tool_choice="auto"
        )
        
        response_message = response.choices[0].message
        
        if hasattr(response, 'usage') and response.usage:
            print(f"Token Usage (Loop {loop_count+1}): Prompt={response.usage.prompt_tokens}, Completion={response.usage.completion_tokens}, Total={response.usage.total_tokens}")
            step_name = ",".join(tc.function.name for tc in response_message.tool_calls) if response_message.tool_calls else "no_tools"
            query_logger.log_loop(f"loop_{loop_count+1}", step_name, response.usage)
        
        # Pydantic/OpenAI parses need the message to be converted to dict sometimes,
        # but in openai>=1.0, we can often just append the model object directly.
        messages.append(response_message)
        
        if not response_message.tool_calls:
            # Done calling tools
            break
            
        for tool_call in response_message.tool_calls:
            tool_name = tool_call.function.name
            try:
                args = json.loads(tool_call.function.arguments)
            except json.JSONDecodeError as e:
                args = {}
                
            print(f"Agent Action -> Calling '{tool_name}' with args: {args}")
            
            # Show exact tool and args in frontend loader
            yield json.dumps({"type": "status", "message": f"Executing: {tool_name} {json.dumps(args)}"}) + "\n"
            
            if tool_name == "direct_fetch_table":
                print(f"Agent Action -> Intercepting Direct Data Hydration request!")
                yield json.dumps({"type": "status", "message": "Direct Data Hydration: Fetching data natively from Gilhari..."}) + "\n"
                
                cls_name = args.get("class_name", "")
                if cls_name and not cls_name.startswith("com.supplychain.model."):
                    cls_name = f"com.supplychain.model.{cls_name}"
                    
                query_args = {"className": cls_name}
                filter_c = args.get("filter_clause", "")
                
                # Strip out hallucinated ORDER BY/LIMIT if they still put it in the filter_clause
                if filter_c:
                    import re
                    filter_c = re.split(r'\bORDER BY\b|\bLIMIT\b', filter_c, flags=re.IGNORECASE)[0].strip()
                    if filter_c:
                        query_args["filter"] = filter_c
                    
                raw_data_str = await mcp_client.call_tool("query", query_args)
                try:
                    raw_data = json.loads(raw_data_str)
                    if isinstance(raw_data, dict):
                        raw_data = [raw_data]
                    elif not isinstance(raw_data, list):
                        raw_data = []
                except:
                    raw_data = []
                    
                # Handle sorting and limiting in python
                sort_col = args.get("sort_column")
                sort_order = args.get("sort_order", "ASC")
                limit_val = args.get("limit")
                
                if sort_col and raw_data:
                    try:
                        raw_data.sort(key=lambda x: (x.get(sort_col) is None, x.get(sort_col)), reverse=(str(sort_order).upper() == "DESC"))
                    except:
                        pass
                        
                if limit_val and isinstance(limit_val, int):
                    raw_data = raw_data[:limit_val]
                    
                columns = args.get("columns", [])
                rows = []
                for obj in raw_data:
                    rows.append([obj.get(col) for col in columns])
                    
                payload = {
                    "columns": columns,
                    "rows": rows
                }
                
                final_data = {
                    "response_type": "table_view",
                    "conversational_text": "Here is the data table you requested. *(Rendered via Direct Data Hydration)*",
                    "payload": payload
                }
                
                yield json.dumps({"type": "final", "data": final_data}) + "\n"
                query_logger.save()
                return
            
            if tool_name in ["insert", "update", "update2", "delete", "delete2"]:
                print(f"Agent Action -> Intercepting data mutation tool {tool_name} for user confirmation!")
                yield json.dumps({"type": "status", "message": "Requires user confirmation for data mutation..."}) + "\n"
                
                final_data = {
                    "response_type": "confirmation_view",
                    "conversational_text": f"I need your confirmation before executing the **{tool_name}** action.",
                    "payload": {
                        "tool_name": tool_name,
                        "args_json": json.dumps(args),
                        "summary": f"The agent is preparing to execute `{tool_name}` with the provided arguments."
                    }
                }
                yield json.dumps({"type": "final", "data": final_data}) + "\n"
                query_logger.save()
                return
                
            if tool_name == "execute_raw_sql":
                print(f"Agent Action -> Executing raw SQL directly via Docker!")
                yield json.dumps({"type": "status", "message": "Executing complex raw SQL natively..."}) + "\n"
                
                sql_q = args.get("sql_query", "")
                if not sql_q.strip().upper().startswith("SELECT"):
                    messages.append({
                        "role": "tool",
                        "tool_call_id": tool_call.id,
                        "content": "Error: execute_raw_sql is restricted to READ-ONLY (SELECT) queries. Use ORMCP tools for mutations."
                    })
                    continue
                    
                import asyncio
                import subprocess
                try:
                    def run_docker_sync():
                        return subprocess.run([
                            "docker", "exec", "-i", "sqlserver", 
                            "/opt/mssql-tools18/bin/sqlcmd", "-S", "localhost", 
                            "-U", "sa", "-P", "YourStrong!Passw0rd", "-C", 
                            "-d", "supply_chain_db", "-Q", sql_q, "-s", ",", "-W"
                        ], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=False)
                    
                    proc = await asyncio.to_thread(run_docker_sync)
                    out_str = proc.stdout.strip()
                    err_str = proc.stderr.strip()
                        
                    if proc.returncode != 0:
                        messages.append({
                            "role": "tool",
                            "tool_call_id": tool_call.id,
                            "content": f"SQL Execution Failed:\n{err_str}\n{out_str}"
                        })
                    else:
                        if len(out_str) > 10000:
                            out_str = out_str[:10000] + "\n...[TRUNCATED]"
                        messages.append({
                            "role": "tool",
                            "tool_call_id": tool_call.id,
                            "content": out_str if out_str else "Command executed successfully (no output)."
                        })
                except Exception as e:
                    messages.append({
                        "role": "tool",
                        "tool_call_id": tool_call.id,
                        "content": f"Failed to run docker process: {str(e)}"
                    })
                continue
            
            result_str = await mcp_client.call_tool(tool_name, args)
            yield json.dumps({"type": "status", "message": f"Analyzing results from {tool_name}..."}) + "\n"
            
            # Truncate massive data to protect token limits
            if len(result_str) > 30000:
                print(f"Agent Action -> Truncating response (length {len(result_str)} exceeded 30000 chars)")
                result_str = result_str[:30000] + "\n\n...[TRUNCATED: The result was too massive and has been cut off to protect token limits. Please use 'getAggregate' or add stricter filters to your query!]"
            
            messages.append({
                "role": "tool",
                "tool_call_id": tool_call.id,
                "content": result_str
            })
    else:
        print("Agent Warning -> Reached maximum loop limit without finishing!")

    print("\nAgent Action -> Generating final structured Generative UI payload...")
    yield json.dumps({"type": "status", "message": "Structuring UI payload..."}) + "\n"
    # Final call to enforce the strict Pydantic schema
    messages.append({
        "role": "system",
        "content": "Now that you have gathered the data, provide your final response using the required JSON schema structure."
    })
    
    final_response = await client.beta.chat.completions.parse(
        model=MODEL_NAME,
        messages=messages,
        response_format=AgentResponse,
    )
    
    if hasattr(final_response, 'usage') and final_response.usage:
        print(f"Token Usage (Final Structuring): Prompt={final_response.usage.prompt_tokens}, Completion={final_response.usage.completion_tokens}, Total={final_response.usage.total_tokens}")
        query_logger.log_loop("final_structuring", "generate_ui_payload", final_response.usage)
        
    parsed = final_response.choices[0].message.parsed
    
    # Format payload (normal path)
    payload = None
    if parsed.response_type == "table_view":
        payload = parsed.table_payload.model_dump() if parsed.table_payload else None
    elif parsed.response_type == "metric_kpi_view":
        payload = [m.model_dump() for m in parsed.metric_kpi_payload] if parsed.metric_kpi_payload else None
    elif parsed.response_type == "timeline_view":
        payload = [t.model_dump() for t in parsed.timeline_payload] if parsed.timeline_payload else None
    elif parsed.response_type == "chart_view":
        payload = parsed.chart_payload.model_dump() if parsed.chart_payload else None
    elif parsed.response_type == "regional_view":
        payload = parsed.regional_payload.model_dump() if parsed.regional_payload else None
    elif parsed.response_type == "kanban_view":
        payload = parsed.kanban_payload.model_dump() if parsed.kanban_payload else None
    elif parsed.response_type == "actionable_form_view":
        payload = parsed.actionable_form_payload.model_dump() if parsed.actionable_form_payload else None
    elif parsed.response_type == "alert_anomaly_view":
        payload = parsed.alert_anomaly_payload.model_dump() if parsed.alert_anomaly_payload else None
    elif parsed.response_type == "confirmation_view":
        payload = parsed.confirmation_payload.model_dump() if parsed.confirmation_payload else None

    final_data = {
        "response_type": parsed.response_type,
        "conversational_text": parsed.conversational_text,
        "payload": payload
    }
    
    yield json.dumps({"type": "final", "data": final_data}) + "\n"
    query_logger.save()

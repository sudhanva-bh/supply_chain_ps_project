import json
from typing import List, Dict, Any, AsyncGenerator, Annotated, Literal
from langchain_openai import ChatOpenAI
try:
    from langchain_google_genai import ChatGoogleGenerativeAI
except ImportError:
    ChatGoogleGenerativeAI = None
from langchain_core.messages import BaseMessage, SystemMessage, HumanMessage, ToolMessage, AIMessage, ToolCall
from langgraph.graph import StateGraph, END
from langgraph.graph.message import add_messages
from typing_extensions import TypedDict
import asyncio
import subprocess
import re

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
            "total_cost_usd": 0.0,
            "error": None
        }
    
    def log_usage(self, step_name: str, usage):
        if not usage: return
        try:
            pt = usage.prompt_tokens
            ct = usage.completion_tokens
            tt = usage.total_tokens
        except AttributeError:
            pt = usage.get("prompt_tokens", 0)
            ct = usage.get("completion_tokens", 0)
            tt = usage.get("total_tokens", 0)
            
        self.query_log["loops"][step_name] = {
            "step": step_name,
            "prompt_tokens": pt,
            "completion_tokens": ct,
            "total_tokens": tt
        }
        self.query_log["total_prompt_tokens"] += pt
        self.query_log["total_completion_tokens"] += ct
        self.query_log["total_tokens"] += tt
        
    def calculate_cost(self):
        cost_file = os.path.join(os.path.dirname(__file__), "api_costs.json")
        try:
            with open(cost_file, "r", encoding="utf-8") as f:
                costs = json.load(f)
            model_costs = costs.get(self.model_name, costs.get("default", {"prompt_cost_per_1m": 0, "completion_cost_per_1m": 0}))
            
            prompt_cost = (self.query_log["total_prompt_tokens"] / 1000000.0) * model_costs["prompt_cost_per_1m"]
            comp_cost = (self.query_log["total_completion_tokens"] / 1000000.0) * model_costs["completion_cost_per_1m"]
            self.query_log["total_cost_usd"] = round(prompt_cost + comp_cost, 6)
        except Exception as e:
            pass

    def save(self):
        self.query_log["end_time_stamp"] = datetime.now(timezone.utc).isoformat()
        self.calculate_cost()

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

from dotenv import load_dotenv
load_dotenv(override=True)

LLM_PROVIDER = os.environ.get("LLM_PROVIDER", "google").lower()

if LLM_PROVIDER == "openai":
    MODEL_NAME = os.environ.get("OPENAI_MODEL_NAME") or "gpt-4o-mini"
    API_URL = "https://api.openai.com/v1"
    llm = ChatOpenAI(
        api_key=os.environ.get("OPENAI_API_KEY", "dummy"),
        model=MODEL_NAME
    )
else:
    MODEL_NAME = os.environ.get("GOOGLE_MODEL_NAME") or "gemini-flash-lite-latest"
    API_URL = "https://generativelanguage.googleapis.com"
    llm = ChatGoogleGenerativeAI(
        api_key=os.environ.get("GEMINI_API_KEY", "dummy"),
        model=MODEL_NAME,
        convert_system_message_to_human=True
    )

print(f"Loaded environment. Provider: {LLM_PROVIDER.upper()}, Model: {MODEL_NAME}, URL: {API_URL}")

SYSTEM_PROMPT = """You are a supply chain business intelligence assistant powered by Gilhari ORM.
Your goal is to answer queries by fetching data, calculating aggregations, or mutating records (create/update/delete) when explicitly requested.

--- 1. DATA READING STRATEGY ---
- MANDATORY SCHEMA DISCOVERY: You MUST use `getObjectModelSummary` FIRST on every new complex request to ensure you have complete clarity on the schema, exact fields, and class names before writing any queries.
- DECISION MAKING (RAW SQL vs ORMCP): After fetching the object model, YOU decide the most efficient path to get the data:
   * Use ORMCP tools (`query`, `getAggregate`) for simple, single-table reads.
   * Use `execute_raw_sql` for complex reads involving JOINs, cross-table filtering, or GROUP BY aggregations.
- SQL CONVENTIONS: When writing raw SQL, remember that SQL Server table names are simply pluralized versions of the Gilhari class names (e.g. `Supplier` -> `Suppliers`, `PurchaseOrder` -> `PurchaseOrders`).
- AVOID DATA DUMPS: NEVER use `query` to fetch entire tables without filters/limits. Avoid hallucinating massive `IN (...)` clauses. If you need cross-table filtering, use `execute_raw_sql`.

--- 2. DATA MUTATION STRATEGY ---
- STRICT TOOL USAGE: `execute_raw_sql` is strictly READ-ONLY. You MUST use the designated ORMCP tools (`insert`, `update`, `delete`) for all data modifications.
- MULTI-HOP REASONING: If updating/deleting an entity based on a related entity's condition, find the relevant primary keys via a bridging table first, then execute the mutation on the exact target IDs. Do not hallucinate fields across unrelated classes.

--- 3. UI RESPONSE GENERATION ---
- DIRECT HYDRATION: If requested to show a data table, use `direct_fetch_table` (if available). For Kanban boards, Charts, or Metrics, YOU MUST fetch the data yourself using `query` or `execute_raw_sql`.
- STOP CALLING TOOLS TO FINISH: Once you have fetched the required data (e.g. from `execute_raw_sql` or `getAggregate`), you MUST STOP calling tools! Simply output a conversational text message (e.g., "I have the data now.") without invoking any tools.
- AUTONOMY: NEVER ask the user for permission to run read tools! You must autonomously execute `query` or `execute_raw_sql` to get the data before finishing.
- Once you stop calling tools, the system will execute a final step where you will be provided with the JSON schemas for the Generative UI (e.g. `chart_view`, `metric_kpi_view`, `timeline_view`, `kanban_view`, etc.). DO NOT try to call these as tools during the data gathering phase! Just gather the data, then stop calling tools.
"""

class AgentState(TypedDict):
    messages: Annotated[List[BaseMessage], add_messages]
    final_payload: Dict[str, Any]
    intercept_msg: str
    status_msg: str
    debug_msgs: List[str]

async def process_chat_message(user_message: str, mcp_client: MCPClient) -> AsyncGenerator[str, None]:
    query_logger = QueryLogger(user_message, MODEL_NAME)
    
    try:
        mcp_tools = await mcp_client.get_langchain_tools()
        
        from langchain_core.tools import StructuredTool
        from pydantic import BaseModel, Field
        from typing import Optional

        class DirectFetchTableArgs(BaseModel):
            class_name: str = Field(description="The fully qualified Gilhari class name (e.g., com.supplychain.model.Supplier). ALWAYS include the com.supplychain.model. prefix!")
            filter_clause: Optional[str] = Field(description="Optional SQL WHERE clause boolean expression ONLY (e.g. deliveryStatus = 'Pending'). NEVER put 'ORDER BY' or 'LIMIT' here! Use the sort_column and limit parameters instead.")
            columns: List[str] = Field(description="List of column names to display in the table")
            sort_column: Optional[str] = Field(description="Optional column name to sort the results by")
            sort_order: Optional[str] = Field("ASC", description="Optional sort direction, either 'ASC' or 'DESC'")
            limit: Optional[int] = Field(description="Optional maximum number of rows to return")

        direct_fetch_table_tool = StructuredTool.from_function(
            name="direct_fetch_table",
            description="Call this tool instead of 'query' when the user asks for a table of data. IMPORTANT: You MUST call 'getObjectModelSummary' first to get the correct fully-qualified 'class_name' and correct 'columns' before calling this tool!",
            args_schema=DirectFetchTableArgs,
            func=lambda **kwargs: "Sync not supported",
            coroutine=lambda **kwargs: asyncio.sleep(0) # Logic handled in execute_tools
        )
        
        class ExecuteRawSqlArgs(BaseModel):
            sql_query: str = Field(description="The exact SQL query to execute. E.g. 'SELECT TOP 5 s.companyName, SUM(poi.quantityOrdered) as totalVol FROM Suppliers s JOIN InventoryItems i ON s.supplierID = i.supplierID JOIN PurchaseOrderItems poi ON i.itemID = poi.itemID GROUP BY s.companyName ORDER BY totalVol DESC'")

        execute_raw_sql_tool = StructuredTool.from_function(
            name="execute_raw_sql",
            description="Execute arbitrary READ-ONLY raw SQL queries directly against the database (supports JOINs, GROUP BYs, etc). IMPORTANT: Only use this for SELECT statements to fetch complex data efficiently. NEVER use this for INSERT, UPDATE, or DELETE. The database is 'supply_chain_db'.",
            args_schema=ExecuteRawSqlArgs,
            func=lambda **kwargs: "Sync not supported",
            coroutine=lambda **kwargs: asyncio.sleep(0) # Logic handled in execute_tools
        )
        
        all_tools = mcp_tools + [execute_raw_sql_tool]
        if "table" in user_message.lower():
            all_tools.append(direct_fetch_table_tool)
            
        llm_with_tools = llm.bind_tools(all_tools)
        
        # Define graph nodes
        async def call_model(state: AgentState):
            messages = state['messages']
            response = await llm_with_tools.ainvoke(messages)
            
            if hasattr(response, "usage_metadata") and response.usage_metadata:
                usage = {
                    "prompt_tokens": response.usage_metadata.get("input_tokens", 0),
                    "completion_tokens": response.usage_metadata.get("output_tokens", 0),
                    "total_tokens": response.usage_metadata.get("total_tokens", 0)
                }
                query_logger.log_usage(f"call_model_{len(messages)}", usage)
            elif getattr(response, "response_metadata", None) and "token_usage" in response.response_metadata:
                query_logger.log_usage(f"call_model_{len(messages)}", response.response_metadata["token_usage"])
            
            debug_msgs = []
            if getattr(response, "tool_calls", None):
                for tc in response.tool_calls:
                    msg = f"Executing tool: {tc['name']} with args: {tc['args']}"
                    debug_msgs.append(msg)
                    print(msg)
            
            return {"messages": [response], "status_msg": "Thinking...", "debug_msgs": debug_msgs}
            
        async def execute_tools(state: AgentState):
            messages = state['messages']
            last_message = messages[-1]
            
            tool_messages = []
            final_payload = None
            intercept_msg = None
            status_msg = f"Executing tools..."
            
            for tool_call in last_message.tool_calls:
                tool_name = tool_call['name']
                args = tool_call['args']
                
                if tool_name == "direct_fetch_table":
                    intercept_msg = "Direct Data Hydration: Fetching data natively from Gilhari..."
                    cls_name = args.get("class_name", "")
                    if cls_name and not cls_name.startswith("com.supplychain.model."):
                        cls_name = f"com.supplychain.model.{cls_name}"
                    
                    query_args = {"className": cls_name}
                    filter_c = args.get("filter_clause", "")
                
                    if filter_c:
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
                
                    query_logger.calculate_cost()
                    final_payload = {
                        "response_type": "table_view",
                        "conversational_text": "Here is the data table you requested. *(Rendered via Direct Data Hydration)*",
                        "payload": payload,
                        "meta": {
                            "total_cost_usd": query_logger.query_log["total_cost_usd"],
                            "total_tokens": query_logger.query_log["total_tokens"]
                        }
                    }
                    tool_messages.append(ToolMessage(content="Completed", tool_call_id=tool_call['id']))
                    break
                    
                elif tool_name in ["insert", "update", "update2", "delete", "delete2"]:
                    intercept_msg = "Requires user confirmation for data mutation..."
                    query_logger.calculate_cost()
                    final_payload = {
                        "response_type": "confirmation_view",
                        "conversational_text": f"I need your confirmation before executing the **{tool_name}** action.",
                        "payload": {
                            "tool_name": tool_name,
                            "args_json": json.dumps(args),
                            "summary": f"The agent is preparing to execute `{tool_name}` with the provided arguments."
                        },
                        "meta": {
                            "total_cost_usd": query_logger.query_log["total_cost_usd"],
                            "total_tokens": query_logger.query_log["total_tokens"]
                        }
                    }
                    tool_messages.append(ToolMessage(content="Completed", tool_call_id=tool_call['id']))
                    break
                    
                elif tool_name == "execute_raw_sql":
                    status_msg = "Executing complex raw SQL natively..."
                    sql_q = args.get("sql_query", "")
                    if not sql_q.strip().upper().startswith("SELECT"):
                        tool_messages.append(ToolMessage(content="Error: execute_raw_sql is restricted to READ-ONLY (SELECT) queries. Use ORMCP tools for mutations.", tool_call_id=tool_call['id']))
                        continue
                        
                    try:
                        def run_sql_sync():
                            import pyodbc
                            import os
                            server = os.environ.get("AZURE_SQL_SERVER")
                            database = os.environ.get("AZURE_SQL_DATABASE")
                            username = os.environ.get("AZURE_SQL_USER")
                            password = os.environ.get("AZURE_SQL_PASSWORD")
                            
                            drivers = [d for d in pyodbc.drivers() if 'SQL Server' in d]
                            if not drivers:
                                raise Exception("No ODBC Driver for SQL Server found. Please install the Microsoft ODBC Driver.")
                            driver = '{ODBC Driver 18 for SQL Server}' if 'ODBC Driver 18 for SQL Server' in drivers else (
                                '{ODBC Driver 17 for SQL Server}' if 'ODBC Driver 17 for SQL Server' in drivers else '{' + drivers[-1] + '}'
                            )
                            
                            conn_str = f"DRIVER={driver};SERVER={server};DATABASE={database};UID={username};PWD={password};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
                            
                            with pyodbc.connect(conn_str) as conn:
                                cursor = conn.cursor()
                                cursor.execute(sql_q)
                                rows = cursor.fetchall()
                                
                                columns = [column[0] for column in cursor.description]
                                out_str = ",".join(columns) + "\n"
                                for row in rows:
                                    out_str += ",".join([str(x) if x is not None else "NULL" for x in row]) + "\n"
                                return out_str, ""
                    
                        out_str, err_str = await asyncio.to_thread(run_sql_sync)
                        
                        if len(out_str) > 10000:
                            out_str = out_str[:10000] + "\n...[TRUNCATED]"
                        tool_messages.append(ToolMessage(content=out_str if out_str else "Command executed successfully (no output).", tool_call_id=tool_call['id']))
                    except Exception as e:
                        tool_messages.append(ToolMessage(content=f"SQL Execution Failed: {str(e)}", tool_call_id=tool_call['id']))
                        
                else:
                    status_msg = f"Analyzing results from {tool_name}..."
                    result_str = await mcp_client.call_tool(tool_name, args)
                    if len(result_str) > 30000:
                        result_str = result_str[:30000] + "\n\n...[TRUNCATED: The result was too massive and has been cut off to protect token limits. Please use 'getAggregate' or add stricter filters to your query!]"
                    tool_messages.append(ToolMessage(content=result_str, tool_call_id=tool_call['id']))

            return {"messages": tool_messages, "final_payload": final_payload, "intercept_msg": intercept_msg, "status_msg": status_msg}

        def should_continue(state: AgentState) -> Literal["execute_tools", END]:
            messages = state['messages']
            last_message = messages[-1]
            
            if state.get("final_payload") is not None:
                return END
                
            if isinstance(last_message, AIMessage) and last_message.tool_calls:
                return "execute_tools"
            return END

        workflow = StateGraph(AgentState)
        workflow.add_node("call_model", call_model)
        workflow.add_node("execute_tools", execute_tools)
        workflow.set_entry_point("call_model")
        workflow.add_conditional_edges("call_model", should_continue)
        workflow.add_edge("execute_tools", "call_model")
        app = workflow.compile()
        
        inputs = {"messages": [SystemMessage(content=SYSTEM_PROMPT), HumanMessage(content=user_message)]}
        
        current_messages = inputs["messages"].copy()
        final_payload = None
        async for event in app.astream(inputs, stream_mode="updates"):
            for node, state_update in event.items():
                if "messages" in state_update:
                    current_messages.extend(state_update["messages"])

                if "status_msg" in state_update and state_update["status_msg"]:
                    yield json.dumps({"type": "status", "message": state_update["status_msg"]}) + "\n"
                    
                if "intercept_msg" in state_update and state_update["intercept_msg"]:
                    yield json.dumps({"type": "status", "message": state_update["intercept_msg"]}) + "\n"

                if "debug_msgs" in state_update and state_update["debug_msgs"]:
                    for dmsg in state_update["debug_msgs"]:
                        yield json.dumps({"type": "debug", "message": dmsg}) + "\n"
                    
                if "final_payload" in state_update and state_update["final_payload"]:
                    final_payload = state_update["final_payload"]
                    yield json.dumps({"type": "final", "data": final_payload}) + "\n"
                    return
        
        if not final_payload:
            yield json.dumps({"type": "status", "message": "Structuring UI payload..."}) + "\n"
            
            structured_llm = llm.with_structured_output(AgentResponse)
            
            struct_msgs = current_messages + [SystemMessage(content="Now that you have gathered the data, provide your final response using the required JSON schema structure.")]
            try:
                parsed = await structured_llm.ainvoke(struct_msgs)
            except Exception as e:
                raise Exception(f"Failed to generate structured UI payload from model: {e}")
            
            # Note: with_structured_output doesn't return raw token usage easily in all LLMs, so we skip cost here or approximate it.
            
            payload = None
            if parsed.response_type == "table_view":
                payload = parsed.table_payload.model_dump() if parsed.table_payload else None
            elif parsed.response_type == "direct_fetch_table":
                payload = parsed.direct_fetch_payload.model_dump() if parsed.direct_fetch_payload else None
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

            query_logger.calculate_cost()
            final_data = {
                "response_type": parsed.response_type,
                "conversational_text": parsed.conversational_text,
                "payload": payload,
                "meta": {
                    "total_cost_usd": query_logger.query_log["total_cost_usd"],
                    "total_tokens": query_logger.query_log["total_tokens"]
                }
            }
            
            print(f"\n[DEBUG] GENERATED UI PAYLOAD:\n{json.dumps(final_data, indent=2)}\n")
        
            yield json.dumps({"type": "final", "data": final_data}) + "\n"
            
    except Exception as e:
        import traceback
        error_msg = f"Error during agent execution: {str(e)}"
        print(f"{error_msg}\n{traceback.format_exc()}")
        query_logger.query_log["error"] = error_msg
        yield json.dumps({"type": "status", "message": f"Fatal Error: {str(e)}"}) + "\n"
    finally:
        query_logger.save()

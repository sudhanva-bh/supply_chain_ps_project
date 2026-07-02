import json
from typing import List, Dict, Any, AsyncGenerator
from openai import AsyncOpenAI

from mcp_client import MCPClient
from models import AgentResponse

import os

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
    MODEL_NAME = "gemini-2.5-flash"
else:
    client = AsyncOpenAI()
    MODEL_NAME = "gpt-4o"

SYSTEM_PROMPT = """You are a read-only supply chain business intelligence assistant.
Your goal is to answer user queries by fetching data across our 6 schemas, calculating aggregations, or performing multi-hop reasoning.
You have access to a set of database tools provided by the ORMCP Semantic Gateway.

Important:
1. ALWAYS use the `getObjectModelSummary` tool first if you are unsure of the schema or exact class names.
2. NEVER use `query` to fetch large datasets (e.g., all items) just to count or sum them. ALWAYS use `getAggregate` for math and aggregations, which computes directly in the database.
3. DIRECT DATA HYDRATION: If the user asks to see a data table (e.g. "List all pending orders"), DO NOT use the `query` tool to fetch the data into your context. Instead, immediately call `direct_fetch_table`. The backend will natively run the query and build a `table_view`, saving tokens.
4. Generative UI Models available:
   - `text_only`: Simple markdown responses.
   - `table_view`: (Use `direct_fetch_table` tool instead for fetching tables directly).
   - `metric_kpi_view`: High-level metrics with trend and colors.
   - `timeline_view`: History of events.
   - `chart_view`: Bar, Pie, or Line charts (`chart_type` must be 'bar', 'pie', or 'line').
   - `regional_view`: Visualizing geographical/regional distributions.
   - `kanban_view`: Kanban board for order statuses or workflows.
   - `actionable_form_view`: Output a form when the user wants to execute an action (e.g. Create Order).
   - `alert_anomaly_view`: Output high-priority red/yellow warnings and anomalies.
5. If a tool call fails with an error, adjust your arguments and try again.
6. Formulate your final response to perfectly utilize the Generative UI models.
"""

async def process_chat_message(user_message: str, mcp_client: MCPClient) -> AsyncGenerator[str, None]:
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": user_message}
    ]

    tools = await mcp_client.get_openai_tools()
    
    # Inject our custom Direct Data Hydration tool
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
                return
            
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

    final_data = {
        "response_type": parsed.response_type,
        "conversational_text": parsed.conversational_text,
        "payload": payload
    }
    
    yield json.dumps({"type": "final", "data": final_data}) + "\n"

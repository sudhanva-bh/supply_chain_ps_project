import json
from typing import List, Dict, Any, AsyncGenerator
from openai import AsyncOpenAI

from mcp_client import MCPClient
from models import AgentResponse

import os

if os.environ.get("GEMINI_API_KEY"):
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
3. If a tool response indicates it was truncated due to massive size, you MUST refine your query by adding strict filters or using `getAggregate` instead.
4. If a tool call fails with an error, adjust your arguments and try again.
5. You are providing data for a Generative UI. Formulate your final response to best fit the user's intent.
"""

async def process_chat_message(user_message: str, mcp_client: MCPClient) -> AsyncGenerator[str, None]:
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": user_message}
    ]

    tools = await mcp_client.get_openai_tools()
    
    # Tool execution loop
    max_loops = 12
    for loop_count in range(max_loops):
        print(f"\n--- Agent Reasoning Loop {loop_count+1}/{max_loops} ---")
        yield json.dumps({"type": "status", "message": f"Reasoning loop {loop_count+1}..."}) + "\n"
        
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
            yield json.dumps({"type": "status", "message": f"Executing tool: {tool_name}"}) + "\n"
            result_str = await mcp_client.call_tool(tool_name, args)
            
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
    
    # Format payload
    payload = None
    if parsed.response_type == "table_view":
        payload = parsed.table_payload.model_dump() if parsed.table_payload else None
    elif parsed.response_type == "metric_kpi_view":
        payload = [item.model_dump() for item in parsed.metric_kpi_payload] if parsed.metric_kpi_payload else None
    elif parsed.response_type == "timeline_view":
        payload = [item.model_dump() for item in parsed.timeline_payload] if parsed.timeline_payload else None
    elif parsed.response_type == "chart_view":
        payload = parsed.chart_payload.model_dump() if parsed.chart_payload else None
        
    final_data = {
        "response_type": parsed.response_type,
        "conversational_text": parsed.conversational_text,
        "payload": payload
    }
    
    yield json.dumps({"type": "final", "data": final_data}) + "\n"

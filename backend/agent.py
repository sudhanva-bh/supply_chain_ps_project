import json
from typing import List, Dict, Any
from openai import AsyncOpenAI
from .mcp_client import MCPClient
from .models import AgentResponse

# Initialize OpenAI client
client = AsyncOpenAI()

SYSTEM_PROMPT = """You are a read-only supply chain business intelligence assistant.
Your goal is to answer user queries by fetching data across our 6 schemas, calculating aggregations, or performing multi-hop reasoning.
You have access to a set of database tools provided by the ORMCP Semantic Gateway.

Important:
1. ALWAYS use the `getObjectModelSummary` tool first if you are unsure of the schema or exact class names.
2. If a tool call fails with an error, read the error message, adjust your arguments, and try again (self-correction).
3. Do not assume primary key types or exact field names; rely on the introspection tool.
4. You are providing data for a Generative UI. Formulate your final response to best fit the user's intent.
"""

async def process_chat_message(user_message: str, mcp_client: MCPClient) -> AgentResponse:
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": user_message}
    ]

    tools = await mcp_client.get_openai_tools()
    
    # Tool execution loop
    while True:
        response = await client.chat.completions.create(
            model="gpt-4o",
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
                
            result_str = await mcp_client.call_tool(tool_name, args)
            
            messages.append({
                "role": "tool",
                "tool_call_id": tool_call.id,
                "content": result_str
            })

    # Final call to enforce the strict Pydantic schema
    messages.append({
        "role": "system",
        "content": "Now that you have gathered the data, provide your final response using the required JSON schema structure."
    })
    
    final_response = await client.beta.chat.completions.parse(
        model="gpt-4o",
        messages=messages,
        response_format=AgentResponse,
    )
    
    return final_response.choices[0].message.parsed

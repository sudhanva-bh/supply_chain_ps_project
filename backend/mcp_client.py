import os
import json
import asyncio
from typing import Dict, Any, List
from mcp.client.stdio import stdio_client, StdioServerParameters
from mcp.client.session import ClientSession
from mcp.types import CallToolResult

class MCPClient:
    def __init__(self):
        # We run the global python module for ormcp_server
        self.server_params = StdioServerParameters(
            command="python",
            args=["-m", "ormcp_server"],
            env=os.environ.copy()
        )
        self.session: ClientSession = None
        self._exit_stack = None

    async def connect(self):
        from contextlib import AsyncExitStack
        self._exit_stack = AsyncExitStack()
        
        # Connect to the stdio server
        read, write = await self._exit_stack.enter_async_context(stdio_client(self.server_params))
        
        # Initialize the session
        self.session = await self._exit_stack.enter_async_context(ClientSession(read, write))
        await self.session.initialize()

    async def disconnect(self):
        if self._exit_stack:
            await self._exit_stack.aclose()
            self.session = None

    async def get_openai_tools(self) -> List[Dict[str, Any]]:
        if not self.session:
            raise Exception("Not connected to MCP server")
            
        tools_resp = await self.session.list_tools()
        
        openai_tools = []
        for tool in tools_resp.tools:
            # Map MCP tool to OpenAI function calling format
            openai_tool = {
                "type": "function",
                "function": {
                    "name": tool.name,
                    "description": tool.description,
                    "parameters": tool.inputSchema
                }
            }
            openai_tools.append(openai_tool)
            
        return openai_tools

    async def call_tool(self, name: str, arguments: Dict[str, Any]) -> str:
        if not self.session:
            raise Exception("Not connected to MCP server")
            
        try:
            result: CallToolResult = await self.session.call_tool(name, arguments)
            
            output = ""
            for content in result.content:
                if content.type == "text":
                    output += content.text
            
            if result.isError:
                return f"Error from tool: {output}"
            return output
        except Exception as e:
            # Return exception text so the LLM can self-correct
            return f"Exception executing tool {name}: {str(e)}"

import os
import json
import asyncio
from typing import Dict, Any, List
from mcp.client.stdio import stdio_client, StdioServerParameters
from mcp.client.session import ClientSession
from mcp.types import CallToolResult

class MCPClient:
    def __init__(self):
        # Resolve the python executable from the ROOT .venv where ormcp-server is installed
        root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
        python_exe = os.path.join(root_dir, '.venv', 'Scripts', 'python.exe')
        
        if not os.path.exists(python_exe):
            python_exe = "python" # fallback
            
        self.server_params = StdioServerParameters(
            command=python_exe,
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

    async def get_langchain_tools(self) -> List[Any]:
        if not self.session:
            raise Exception("Not connected to MCP server")
            
        tools_resp = await self.session.list_tools()
        
        from langchain_core.tools import StructuredTool
        from pydantic import create_model, Field
        from typing import Any
        
        langchain_tools = []
        for tool in tools_resp.tools:
            fields = {}
            properties = tool.inputSchema.get("properties", {})
            required = tool.inputSchema.get("required", [])
            for prop_name, prop_info in properties.items():
                prop_type = str
                if prop_info.get("type") == "integer":
                    prop_type = int
                elif prop_info.get("type") == "number":
                    prop_type = float
                elif prop_info.get("type") == "boolean":
                    prop_type = bool
                elif prop_info.get("type") == "array":
                    prop_type = list
                
                default = ... if prop_name in required else None
                fields[prop_name] = (prop_type, Field(default, description=prop_info.get("description", "")))
            
            ArgsSchema = create_model(f"{tool.name}Args", **fields)
            
            def create_run(t_name):
                async def _run(**kwargs) -> str:
                    return await self.call_tool(t_name, kwargs)
                return _run

            lc_tool = StructuredTool(
                name=tool.name,
                description=tool.description or "No description",
                args_schema=ArgsSchema,
                coroutine=create_run(tool.name),
                func=lambda **kwargs: "Sync not supported"
            )
            langchain_tools.append(lc_tool)
            
        return langchain_tools

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

import os
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from dotenv import load_dotenv

from mcp_client import MCPClient
from agent import process_chat_message
from models import AgentResponse

load_dotenv(override=True)

mcp_client = MCPClient()

@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        print("Connecting to ORMCP Server via stdio...")
        await mcp_client.connect()
        print("Successfully connected to ORMCP Server.")
    except Exception as e:
        print(f"Failed to connect to ORMCP Server: {e}")
        
    yield
    
    print("Disconnecting from ORMCP Server...")
    await mcp_client.disconnect()

app = FastAPI(title="Supply Chain AI Backend", lifespan=lifespan)

class ChatRequest(BaseModel):
    message: str

class ExecuteToolRequest(BaseModel):
    tool_name: str
    args_json: str

@app.post("/api/agentic-chat")
async def agentic_chat(request: ChatRequest):
    if not os.environ.get("OPENAI_API_KEY") and not os.environ.get("GEMINI_API_KEY"):
        raise HTTPException(status_code=500, detail="OPENAI_API_KEY or GEMINI_API_KEY is not set in the environment.")
        
    return StreamingResponse(process_chat_message(request.message, mcp_client), media_type="application/x-ndjson")

@app.post("/api/execute-tool")
async def execute_tool(request: ExecuteToolRequest):
    import json
    try:
        args = json.loads(request.args_json)
    except Exception as e:
        raise HTTPException(status_code=400, detail="Invalid JSON arguments")
    
    try:
        result = await mcp_client.call_tool(request.tool_name, args)
        return {"status": "success", "result": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)

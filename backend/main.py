import os
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from dotenv import load_dotenv
import httpx
from fastapi import Depends, Header


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

async def verify_password(x_app_password: str = Header(None, alias="X-App-Password")):
    app_password = os.environ.get("APP_PASSWORD")
    if not app_password:
        return True # If not configured, allow access
    if x_app_password != app_password:
        raise HTTPException(status_code=401, detail="Invalid or missing X-App-Password header")
    return True

class ChatRequest(BaseModel):
    message: str

class ExecuteToolRequest(BaseModel):
    tool_name: str
    args_json: str

@app.post("/api/agentic-chat", dependencies=[Depends(verify_password)])
async def agentic_chat(request: ChatRequest):
    if not os.environ.get("OPENAI_API_KEY") and not os.environ.get("GEMINI_API_KEY"):
        raise HTTPException(status_code=500, detail="OPENAI_API_KEY or GEMINI_API_KEY is not set in the environment.")
        
    return StreamingResponse(process_chat_message(request.message, mcp_client), media_type="application/x-ndjson")

@app.post("/api/execute-tool", dependencies=[Depends(verify_password)])
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

@app.get("/api/auth/verify", dependencies=[Depends(verify_password)])
async def auth_verify():
    return {"status": "success"}

@app.api_route("/api/gilhari/{path:path}", methods=["GET", "POST", "PUT", "DELETE"], dependencies=[Depends(verify_password)])
async def proxy_gilhari(path: str, request: Request):
    gilhari_url = f"http://127.0.0.1:80/gilhari/v1/{path}"
    async with httpx.AsyncClient(timeout=120.0) as client:
        body = await request.body()
        headers = dict(request.headers)
        headers.pop("host", None) # Remove host header so httpx uses the correct one
        
        # We need to make sure we don't pass X-App-Password to Gilhari
        headers.pop("x-app-password", None)
        
        try:
            response = await client.request(
                method=request.method,
                url=gilhari_url,
                headers=headers,
                content=body,
                params=request.query_params
            )
            # Read the response content fully before the client context closes
            response_content = response.content
            return Response(
                content=response_content,
                status_code=response.status_code,
                headers=dict(response.headers)
            )
        except Exception as e:
            raise HTTPException(status_code=502, detail=f"Bad Gateway: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)

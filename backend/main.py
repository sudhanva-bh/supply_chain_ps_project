import os
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from dotenv import load_dotenv

from .mcp_client import MCPClient
from .agent import process_chat_message

load_dotenv()

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

@app.post("/api/agentic-chat")
async def agentic_chat(request: ChatRequest):
    if not os.environ.get("OPENAI_API_KEY"):
        raise HTTPException(status_code=500, detail="OPENAI_API_KEY is not set in the environment.")
        
    try:
        agent_response = await process_chat_message(request.message, mcp_client)
        
        payload = None
        if agent_response.response_type == "table_view":
            payload = agent_response.table_payload.model_dump() if agent_response.table_payload else None
        elif agent_response.response_type == "metric_kpi_view":
            payload = [item.model_dump() for item in agent_response.metric_kpi_payload] if agent_response.metric_kpi_payload else None
        elif agent_response.response_type == "timeline_view":
            payload = [item.model_dump() for item in agent_response.timeline_payload] if agent_response.timeline_payload else None
        elif agent_response.response_type == "chart_view":
            payload = agent_response.chart_payload.model_dump() if agent_response.chart_payload else None
            
        return {
            "response_type": agent_response.response_type,
            "conversational_text": agent_response.conversational_text,
            "payload": payload
        }
        
    except Exception as e:
        print(f"Error processing chat: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("backend.main:app", host="0.0.0.0", port=8000, reload=True)

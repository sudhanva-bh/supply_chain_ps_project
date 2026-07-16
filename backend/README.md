# Backend — Agentic AI Service

[![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi)](https://fastapi.tiangolo.com/)
[![LangChain](https://img.shields.io/badge/LangChain-1C3C3C?style=for-the-badge&logo=langchain&logoColor=white)](https://www.langchain.com/)
![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)
[![ORMCP](https://img.shields.io/badge/ORMCP-MCP%20Server-8A2BE2?style=for-the-badge)](https://pypi.org/project/ormcp-server/)

> Part of the [Agentic Supply Chain Intelligence Platform](../README.md). Also see the [Frontend README](../admin_dashboard/README.md).

---

## Overview

This directory contains the FastAPI-based agentic backend that powers the AI Analytics feature of the supply chain dashboard. It fulfills three responsibilities:

1. **MCP Client Lifecycle Management.** On startup, the server spawns and connects to the ORMCP server process via standard I/O (`stdio`). The ORMCP server introspects the running Gilhari microservice and exposes the supply chain database as a collection of typed MCP tools. This connection is maintained for the lifetime of the FastAPI process.

2. **Agentic LangGraph Loop.** When a chat request arrives, a LangGraph `StateGraph` takes control. It runs an iterative tool-calling loop: the LLM selects an MCP tool, the backend executes it against the real database, the result is appended to the message history, and the process repeats until the agent determines it has enough data to generate a response.

3. **Generative UI Response.** After the tool-calling phase ends, the LLM is prompted a final time with a strict JSON schema (`AgentResponse`) and a gallery of UI payload definitions. It selects the most appropriate visualization type (chart, table, Kanban board, KPI cards, etc.) and populates the payload with the data it gathered. The result is streamed as newline-delimited JSON (NDJSON) to the Flutter frontend.

---

## Directory Structure

| File | Purpose |
|---|---|
| `main.py` | FastAPI application entry point. Defines API endpoints and manages the ORMCP connection lifecycle via `lifespan`. |
| `agent.py` | Core agentic logic. Implements the `QueryLogger`, the LangGraph `StateGraph` agentic loop, the system prompt, and the two-phase (tool-calling + structured output) execution pipeline. |
| `mcp_client.py` | `MCPClient` class that wraps the MCP `ClientSession`. Handles connecting to the ORMCP stdio server, listing tools, and calling tools. Converts MCP tool schemas to both OpenAI function-calling format and LangChain `StructuredTool` format. |
| `models.py` | Pydantic models for all Generative UI payload types and the top-level `AgentResponse` discriminated union. |
| `modify_agent.py` | Utility script for one-off data modifications via the agent outside of the main API flow. |
| `debug_log.py` | Logging utilities for debugging agent tool-call sequences. |
| `requirements.txt` | Python package dependencies. |
| `.env.example` | Template for the required environment variables. Copy to `.env` and fill in before running. |
| `logs/` | Per-day JSON log files recording every agent query, token usage, cost, and tool-call sequence. |

---

## Prerequisites

- Python 3.10 or later
- The `ormcp-server` package installed in the root `.venv` (at `../.venv/Scripts/python.exe`)
- The Docker infrastructure (SQL Server and Gilhari) must be running before starting this service

---

## Installation

```cmd
# From the backend/ directory
python -m venv .venv --system-site-packages
.\.venv\Scripts\activate
pip install -r requirements.txt
```

---

## Environment Configuration

Copy the example environment file and open it in an editor:
```cmd
copy .env.example .env
```

| Variable | Description | Default |
|---|---|---|
| `LLM_PROVIDER` | Which LLM provider to use: `google` or `openai` | `google` |
| `GEMINI_API_KEY` | Google Gemini API key (used when `LLM_PROVIDER=google`) | — |
| `GOOGLE_MODEL_NAME` | Gemini model identifier | `gemini-flash-lite-latest` |
| `OPENAI_API_KEY` | OpenAI API key (used when `LLM_PROVIDER=openai`) | — |
| `OPENAI_MODEL_NAME` | OpenAI model identifier | `gpt-4o-mini` |
| `GILHARI_BASE_URL` | Base URL of the Gilhari REST microservice | `http://localhost:80/gilhari/v1/` |
| `MCP_SERVER_NAME` | Logical name for the MCP server instance | `SupplyChainMCP` |
| `APP_PASSWORD` | Optional password for the `X-App-Password` request header | `secret123` |

---

## Running the Server

```cmd
uvicorn main:app --port 8001 --reload
```

On startup, the console will print:
```
Connecting to ORMCP Server via stdio...
Successfully connected to ORMCP Server.
Loaded environment. Provider: GOOGLE, Model: gemini-flash-lite-latest, URL: https://generativelanguage.googleapis.com
```

The ORMCP server process is spawned automatically as a child of the FastAPI process and will be terminated when the server shuts down.

---

## API Endpoints

### POST `/api/agentic-chat`

Accepts a natural language message and streams an `AgentResponse` as NDJSON.

**Request headers:**
```
Content-Type: application/json
X-App-Password: secret123
```

**Request body:**
```json
{
  "message": "Show me a bar chart of inventory items by category."
}
```

**Response:** A stream of newline-delimited JSON lines. The final line contains the complete `AgentResponse` object.

**Example (PowerShell):**
```powershell
Invoke-RestMethod -Method Post -Uri "http://localhost:8001/api/agentic-chat" `
  -Headers @{"Content-Type"="application/json"; "X-App-Password"="secret123"} `
  -Body '{"message": "What are the top 5 most expensive inventory items?"}'
```

---

### POST `/api/execute-tool`

Directly invokes a named MCP tool with the provided JSON arguments. Used by the frontend `confirmation_view` to execute a mutation after the user confirms.

**Request body:**
```json
{
  "tool_name": "insert_StockTransaction",
  "args_json": "{\"itemID\": 101, \"quantityChanged\": -5, \"transactionType\": \"SALE\", \"timestamp\": \"2024-01-15T10:00:00\"}"
}
```

---

### GET `/api/auth/verify`

Verifies that the provided `X-App-Password` header is valid. Used by the Flutter frontend to check authentication on startup.

---

### ALL `/api/gilhari/{path}`

A reverse proxy that forwards all HTTP methods (GET, POST, PUT, DELETE) to the Gilhari microservice at `http://127.0.0.1:80/gilhari/v1/{path}`. This allows the Flutter frontend to route all Gilhari calls through the authenticated FastAPI server rather than calling the Gilhari container directly.

---

## Agent Architecture

The agent is implemented as a LangGraph `StateGraph` with two nodes:

### Node 1: `call_model`

Invokes the LLM with the current message history and the full set of LangChain-wrapped MCP tools. If the model returns tool calls, the state transitions to `execute_tools`. If it returns a plain text message with no tool calls, the loop ends and transitions to the final structured output step.

### Node 2: `execute_tools`

Iterates over all tool calls in the last model message and executes each against the ORMCP server via `MCPClient.call_tool()`. Tool results are appended to the message history as `ToolMessage` objects. The state transitions back to `call_model`.

### Final Step: Structured Output

After the tool-calling loop exits, the LLM is called one final time. Its output is forced to conform to the `AgentResponse` Pydantic schema using LangChain's `with_structured_output()`. This produces the Generative UI payload that is streamed to the frontend.

### System Prompt Summary

The agent operates under a detailed system prompt that instructs it to:

- Always call `getObjectModelSummary` first on complex requests to confirm field names and class names
- Prefer ORMCP tools for simple single-table reads and `execute_raw_sql` for JOINs and aggregations
- Never use `execute_raw_sql` for mutations — always use the designated `insert`, `update`, and `delete` tools
- Stop calling tools once sufficient data has been gathered, then allow the system to invoke the structured output step

---

## Generative UI Payload Types

The `AgentResponse` model in `models.py` defines the full schema:

| Response Type | Payload Class | Description |
|---|---|---|
| `text_only` | None | Plain markdown text; no structured payload |
| `table_view` | `TableViewPayload` | Static table with `columns` and `rows` arrays |
| `direct_fetch_table` | `DirectFetchTablePayload` | Instructs the frontend to fetch data directly from Gilhari using a class name and optional filter |
| `metric_kpi_view` | `List[MetricKPIViewPayload]` | One or more KPI cards with `title`, `value`, `trend`, and `color` |
| `chart_view` | `ChartViewPayload` | Bar, pie, or line chart with `labels` and `values` |
| `timeline_view` | `List[TimelineViewPayload]` | Ordered event list with `timestamp`, `title`, `subtitle`, and `icon` |
| `kanban_view` | `KanbanViewPayload` | `columns` list and `cards` list where each card maps to a column |
| `regional_view` | `RegionalViewPayload` | Named regions with `value` and `percentage` for map visualization |
| `actionable_form_view` | `ActionableFormViewPayload` | Dynamic form definition with typed fields for data entry via the agent |
| `alert_anomaly_view` | `AlertAnomalyViewPayload` | List of alerts with `severity`, `title`, `description`, and `suggested_action` |
| `confirmation_view` | `ConfirmationViewPayload` | Pre-execution confirmation containing the `tool_name` and `args_json` to execute |

---

## Token Usage and Cost Logging

Every query is logged to a daily JSON file in `logs/log_YYYY-MM-DD.json`. Each entry records:

- The user message and model name
- Prompt and completion token counts per LangGraph loop iteration
- Total tokens and estimated cost in USD (calculated from `api_costs.json`)
- Start and end timestamps
- Any errors encountered

---

## Testing

Verify the backend is accepting requests:
```cmd
python test_api.py
```

Verify raw SQL connectivity to the database:
```cmd
python test_sql.py
```

Open the interactive Swagger documentation:
```
http://localhost:8001/docs
```

---

## Dependencies

| Package | Purpose |
|---|---|
| `fastapi` | Web framework and HTTP server |
| `uvicorn` | ASGI server |
| `langchain` / `langchain-openai` / `langchain-google-genai` | LLM provider abstractions and tool-calling wrappers |
| `langgraph` | Stateful agentic loop framework |
| `mcp` | Model Context Protocol client for communicating with the ORMCP server |
| `pydantic` | Data validation and structured output schema definitions |
| `python-dotenv` | Environment variable loading from `.env` |
| `httpx` | Async HTTP client used by the Gilhari reverse proxy |
| `openai` | OpenAI API client (used when `LLM_PROVIDER=openai`) |

# Supply Chain Database Backend

This project is a comprehensive Supply Chain Management system that combines a robust Microsoft SQL Server backend with a Gilhari REST microservice, an ORMCP Semantic Gateway (MCP Server), a FastAPI agentic AI backend, and a complete Flutter web dashboard. It enables AI-driven data analytics and manipulation directly through the user interface using Generative UI payloads.

## Database Tables Overview

The system manages the supply chain using the following 6 core tables:
- **Suppliers**: Stores information about the vendors providing inventory items, including contact details and regions.
- **ItemCategories**: Categorizes the inventory items into different classifications for organization.
- **InventoryItems**: The core catalog of products managed in the warehouse, tracking current stock levels, pricing, and associations with suppliers and categories.
- **PurchaseOrders**: Tracks purchase orders made for inventory items, including order dates, total costs, and delivery statuses.
- **PurchaseOrderItems**: A bridging table mapping individual items and quantities to specific purchase orders, recording negotiated prices.
- **StockTransactions**: An audit log tracking all movements of inventory, recording the quantity changed, transaction type (e.g., restock, sale, return), and timestamps.

## Prerequisites

- **Docker Desktop** installed and running.
- **Python 3.x** installed (only needed if you want to run the automatic seeding script).
- **Java JDK** (only needed if you want to re-compile the Java container models).

## How to Run

### 1. (Optional) Compile the Java Models
The Java model classes must be compiled into the `bin` directory before building the Docker image. If you modify any `.java` files in the `src` directory, run:
```cmd
.\compile.cmd
```

### 2. Start the Infrastructure
Spin up both the Microsoft SQL Server and the custom Gilhari Microservice using Docker Compose:
```cmd
docker-compose up -d --build
```
*Note: Wait about 10-20 seconds for the SQL Server instance to fully initialize on port `1433`.*

### 3. Initialize the Database Schema
Before Gilhari can interact with the database, you must create the tables using the provided SQL initialization script. The easiest way to do this is to execute the script directly inside the SQL Server container:

```cmd
docker cp sql\init.sql sqlserver:/init.sql
docker exec -it sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong!Passw0rd" -C -i /init.sql
```
*(Alternatively, you can connect a database client like SSMS or Azure Data Studio to `localhost:1433` and execute `sql\init.sql` manually).*

### 4. Verify the Gilhari Service
Once the database is initialized, Gilhari will be able to perform object-relational mapping seamlessly. Run a simple health check or fetch to confirm:
```cmd
curl.exe -X GET "http://localhost/gilhari/v1/health/check"
curl.exe -X GET "http://localhost/gilhari/v1/InventoryItem"
```

## Populating with Random Data

A Python script `seed.py` is included to easily inject randomized seed data directly into your running SQL Server through the Gilhari REST API layer.

1. Install the required Python library:
   ```cmd
   pip install requests
   ```
2. Run the seeding script:
   ```cmd
   python seed.py
   ```

2. Alternatively run the lite seeding script:
   ```cmd
   python seed_lite.py
   ```
This script will auto-generate non-colliding IDs and POST multiple random `Suppliers`, `ItemCategories`, `InventoryItems`, `PurchaseOrders`, `PurchaseOrderItems`, and `StockTransactions` directly to your local Gilhari instance.

## Running the Frontend Dashboard

A complete Flutter web frontend is provided in the `admin_dashboard` directory to interact with the Gilhari REST API. 
To run it locally during development without encountering Cross-Origin Resource Sharing (CORS) errors, you must disable Chrome's strict web security flags:

1. Navigate to the dashboard folder:
   ```cmd
   cd admin_dashboard
   ```
2. Run the Flutter app with web security disabled:
   ```cmd
   flutter run -d chrome --web-browser-flag "--disable-web-security"
   ```
This will launch a dedicated Chrome instance capable of communicating flawlessly with your local Gilhari backend container.

## AI Semantic Gateway (MCP)

This project includes a Model Context Protocol (MCP) server that seamlessly bridges your AI clients (like Claude Desktop) to the supply chain database. It uses the `ormcp-server` to automatically introspect the database schema and expose CRUD capabilities (query, insert, update, delete) directly to your LLM.

To start the MCP server:

1. Ensure the Gilhari microservice and SQL Server are running.
2. Run the provided batch script to launch the ORMCP gateway. If you are using PowerShell or Bash, you must include the `.\` or `./` prefix:
   ```cmd
   .\start_ormcp.bat
   ```
   *Note: This script will automatically create a Python virtual environment, hook into the globally installed `ormcp-server` package, and start the server in `stdio` mode.*

3. Once running, you can configure any standard MCP Client (such as Claude Desktop) to use `start_ormcp.bat` (or `.\start_ormcp.bat` depending on the client's shell context) as your server endpoint.

### Verifying the MCP Server

You can verify the MCP server functionality without Claude by running the local Python validation script:
```cmd
python test_mcp_client.py
```
This script performs an automated handshake, introspects the available AI tools from the Gilhari instance, and dumps the resulting JSON schemas to `mcp_tools_output.log` for your review.

## Agentic Generative UI Backend (Phase 4)

A FastAPI backend sits in the `backend/` directory, serving as an agentic AI bridge between your frontend and the supply chain MCP tools. It uses OpenAI's Structured Outputs (`gpt-4o`) to fetch, aggregate, and map data into dynamic formats like tables, charts, or KPIs.

### Setup Instructions

1. Navigate to the `backend/` directory:
   ```cmd
   cd backend
   ```
2. Create a Python virtual environment (If not done already):
   ```cmd
   python -m venv .venv --system-site-packages
   ```

3. Activate Python virtual environment:
   ```cmd
   .\.venv\Scripts\activate
   ```
   *(For bash/Linux users: `source .venv/bin/activate`)*

3. Open the `backend/.env` file and insert your actual `OPENAI_API_KEY`.
4. Install the required Python dependencies:
   ```cmd
   pip install -r requirements.txt
   ```
5. Start the FastAPI development server:
   ```cmd
   uvicorn main:app --port 8001 --reload
   ```

*(Note: The FastAPI server automatically spawns and manages the `ormcp-server` MCP connection in the background).*

Once the server is running on port 8001, you can interact with the AI agent via the `POST /api/agentic-chat` endpoint.

## Component Verification (Testing)

Use the following commands to verify that each component of the architecture is properly running:

### 1. SQL Server Database
Verify the SQL Server container is running and accepting queries:
```cmd
docker exec -it sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong!Passw0rd" -Q "SELECT @@VERSION"
```

### 2. Gilhari REST Microservice
Verify the Gilhari engine is successfully exposing the data model:
```cmd
curl.exe -X GET "http://localhost/gilhari/v1/health/check"
```

### 3. ORMCP Semantic Gateway (MCP Server)
*(Ensure `start_ormcp.bat` is already running in a separate terminal)*
Verify the MCP Server connects to Gilhari and exposes the database tools:
```cmd
python test_mcp_client.py
```

### 4. FastAPI Agentic Backend
*(Ensure you are in the `backend/` directory and `uvicorn main:app --port 8001 --reload` is running)*
You can test the agent interactively by visiting the auto-generated Swagger UI in your browser:
**http://localhost:8001/docs**

Alternatively, trigger it via PowerShell:
```cmd
Invoke-RestMethod -Method Post -Uri "http://localhost:8001/api/agentic-chat" -Headers @{"Content-Type"="application/json"} -Body '{"message": "Hello"}'
```

### 5. Flutter Admin Dashboard (Generative UI)
*(Ensure `flutter run -d chrome --web-browser-flag "--disable-web-security"` is running)*
Simply open the provided Chrome instance and click on the **AI Analytics** sidebar tab to visually verify the frontend integration!

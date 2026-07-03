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

## Setting up

Please choose the setup guide that matches your current situation:
- [Brand New Setup](#brand-new-setup) (First time running the project)
- [Starting Up Everything Once Again](#starting-up-everything-once-again) (Resuming work on an existing project)
- [Shutting Everything Down](#shutting-everything-down) (Safely stopping all components)

---

### Brand New Setup

Follow these steps if this is your very first time running the project, or if you deleted your Docker volumes and need to start fresh.

#### 1. Docker (Infrastructure & Database)
*(Optional)* If you modified any `.java` files in the `src` directory, first run `.\compile.cmd` to compile the Java models into the `bin` directory before building the Docker image.

Spin up the Microsoft SQL Server and the custom Gilhari Microservice:
```cmd
docker-compose up -d --build
```
*Wait about 10-20 seconds for the SQL Server instance to fully initialize on port `1433`.*

Next, initialize the database schema and populate it with data:
```cmd
docker cp sql\init.sql sqlserver:/init.sql
docker exec -it sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong!Passw0rd" -C -i /init.sql
```
Then, install the python requests library and seed the database:
```cmd
pip install requests
python seed.py
```
*(Alternatively, run `python seed_lite.py` for a smaller dataset).*

#### 2. ORMCP (Semantic Gateway)
*(Note: The FastAPI backend automatically spawns the ORMCP server in the background, but if you want to run it standalone for Claude Desktop, use `.\start_ormcp.bat`)*

#### 3. Backend (Agentic AI API)
Navigate to the `backend/` directory, set up your Python environment, and start the FastAPI server:
```cmd
cd backend
python -m venv .venv --system-site-packages
.\.venv\Scripts\activate
pip install -r requirements.txt
```
**Important:** Make sure you open the `backend/.env` file and insert your actual `OPENAI_API_KEY`. 

Then start the server:
```cmd
uvicorn main:app --port 8001 --reload
```

#### 4. Frontend (Flutter Dashboard)
Open a new terminal, navigate to the `admin_dashboard` directory, and launch the web app with security disabled (to prevent CORS errors during local development):
```cmd
cd admin_dashboard
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

---

### Starting Up Everything Once Again

Because `docker-compose.yml` uses a persistent volume (`sqlserver_data`), your database and seeded data are completely safe. When resuming work, you **do not** need to run any initialization or seeding scripts.

#### 1. Docker
Start the existing infrastructure:
```cmd
docker-compose up -d
```

#### 2. ORMCP
No standalone action needed. The backend will automatically manage the MCP connection.

#### 3. Backend
Open a terminal, activate your existing virtual environment, and start the API:
```cmd
cd backend
.\.venv\Scripts\activate
uvicorn main:app --port 8001 --reload
```

#### 4. Frontend
Open another terminal and launch the dashboard:
```cmd
cd admin_dashboard
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

---

### Shutting Everything Down

To safely stop all components without losing your permanent data:

#### 1. Frontend
In the terminal running the Flutter app, press `q` to quit the Chrome instance and stop the server.

#### 2. Backend & ORMCP
In the terminal running the FastAPI server, press `Ctrl + C` to stop the API. This will also automatically terminate the background ORMCP server.

#### 3. Docker
Tear down the containers safely (your database volume will be preserved):
```cmd
docker-compose down
```

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

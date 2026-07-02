# Supply Chain Database Backend

This project sets up a Microsoft SQL Server database alongside a Gilhari REST microservice for a 6-table supply chain system.

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
curl -X GET "http://localhost/gilhari/v1/health/check"
curl -X GET "http://localhost/gilhari/v1/InventoryItem"
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

An enterprise-grade, 6-table database architecture provides the necessary structural complexity to fully showcase the capabilities of your hybrid platform. This setup challenges both your manual CRUD layer (via nested JSON objects) and your AI agent (via complex multi-table relational navigation).

---

## 🗄️ Database Architecture (6-Table Enterprise Schema)

This schema represents a fully normalized relational structure optimized for an inventory tracking and supply chain logging system on **Azure SQL Server**.

| Table Name | Purpose | Key Columns & Data Types | Relationships |
| --- | --- | --- | --- |
| **`Suppliers`** | Profile information for active product vendors. | `SupplierID` (INT, PK)<br>

<br>`CompanyName` (VARCHAR)<br>

<br>`ContactEmail` (VARCHAR)<br>

<br>`Region` (VARCHAR) | One-to-Many with `InventoryItems` |
| **`ItemCategories`** | Dynamic product classifications. | `CategoryID` (INT, PK)<br>

<br>`CategoryName` (VARCHAR)<br>

<br>`Description` (TEXT) | One-to-Many with `InventoryItems` |
| **`InventoryItems`** | Central log of live stock assets and specs. | `ItemID` (INT, PK)<br>

<br>`Name` (VARCHAR)<br>

<br>`StockQuantity` (INT)<br>

<br>`UnitPrice` (DECIMAL)<br>

<br>`CategoryID` (INT, FK)<br>

<br>`SupplierID` (INT, FK) | Many-to-One with `ItemCategories`, `Suppliers` |
| **`PurchaseOrders`** | Master headers for restock shipments. | `OrderID` (INT, PK)<br>

<br>`OrderDate` (DATETIME)<br>

<br>`TotalCost` (DECIMAL)<br>

<br>`DeliveryStatus` (VARCHAR) | One-to-Many with `PurchaseOrderItems` |
| **`PurchaseOrderItems`** | Junction table detailing items inside an order. | `OrderItemID` (INT, PK)<br>

<br>`OrderID` (INT, FK)<br>

<br>`ItemID` (INT, FK)<br>

<br>`QuantityOrdered` (INT)<br>

<br>`NegotiatedPrice` (DECIMAL) | Many-to-One with `PurchaseOrders`, `InventoryItems` |
| **`StockTransactions`** | Historical immutable audit log for stock tracking. | `TransactionID` (INT, PK)<br>

<br>`ItemID` (INT, FK)<br>

<br>`QuantityChanged` (INT)<br>

<br>`TransactionType` (VARCHAR)<br>

<br>`Timestamp` (DATETIME) | Many-to-One with `InventoryItems` |

---

## 🏗️ Architectural Flow Overview

```text
                           [ Flutter Web Admin Dashboard ]
                                          │
          ┌───────────────────────────────┴──────────────────────────────┐
          ▼ (Pathway A: Manual CRUD)                                     ▼ (Pathway B: Agentic AI Queries)
          │                                                    [ OpenAI Agents SDK App ]
          │                                                              │ (MCP Tool Calls)
          │                                                    [ ORMCP Server (Python) ]
          │                                                              │ (REST API / JSON)
          └───────────────────────────────┬──────────────────────────────┘
                                          ▼ 
                           [ Gilhari Microservice (Docker) ]
                                          │ (Microsoft JDBC Driver)
                                          ▼
                             [ Azure SQL Server Database ]

```

---

## 📋 Detailed Component Breakdown

### 1. Frontend Layer: Flutter Web App

The system cockpit is structured entirely within a single-page responsive web dashboard built in Flutter.

* **Manual CRUD Interfaces:** Contains standard administrative grid views, forms, and modification inputs. When records are manipulated manually, the app directly invokes the REST API surface endpoints exposed by Gilhari.
* **Agentic Chat Console:** A clean panel dedicated to natural language input. It converts user text strings into API requests targeting the Python backend running the OpenAI Agents SDK, waiting to display the processed, formatted text or markdown charts returned by the LLM.

### 2. Data Definition Layer: JDX Mapping & Container Classes

This layer maps your database entities directly to pure object representations without requiring raw SQL statements inside the code.

* **Container Entities:** A set of simple Java classes extending `JDX_JSONObject` created to match each table (e.g., `Supplier`, `InventoryItem`, `StockTransaction`).
* **JDX Grammar Configuration File (`.jdx`):** Explicitly states how object fields translate into relational attributes, handling primary/foreign key definitions and object relationships (such as nesting arrays of `PurchaseOrderItems` within a `PurchaseOrder` object payload).

### 3. Data Abstraction Layer: Gilhari Microservice

A framework packaged as a Docker container that handles automated data persistence.

* **Dynamic REST Generation:** Gilhari reads the compiled entity files and `.jdx` file mappings to instantiate standard RESTful routing endpoints out of the box (e.g., `POST /gilhari/v1/InventoryItems`, `GET /gilhari/v1/PurchaseOrders`).
* **Database Driver Connectivity:** Utilizing the **Microsoft SQL Server JDBC driver**, it safely reads and writes to Azure SQL by handling all serialization between JSON text structures and relational data tables seamlessly.

### 4. Semantic Gateway Layer: ORMCP Server

A Python-based framework implementing Anthropic's open-source Model Context Protocol to serve as the gateway for the artificial intelligence model.

* **Schema Introspection:** Automatically inspects the exposed JSON structures and REST patterns on the active Gilhari instance.
* **MCP Tool Conversion:** Translates those endpoints into strict Model Context Protocol functional declarations (such as a tool named `query_InventoryItems` or `insert_StockTransactions`). It allows the model to see your database as safe, predictable object mutation and lookup tools rather than free-form text entry windows.

### 5. AI Orchestration Layer: OpenAI Agents SDK Application

A distinct Python microservice that controls the operational agentic logic.

* **Function Calling Loop:** Uses an OpenAI model (e.g., GPT-4o) and connects directly to the local or cloud ORMCP host.
* **Payload Verification and Processing:** When the user types an analytical query, the model targets the necessary object tools provided by ORMCP. If Gilhari flags a payload validation issue or constraint error, the model reads the structured message, adjusts its input values, and retries the operation automatically before delivering a clean conversational response back to your Flutter web dashboard.
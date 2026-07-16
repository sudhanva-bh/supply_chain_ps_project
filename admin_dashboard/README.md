# Frontend — Flutter Web Admin Dashboard

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Riverpod](https://img.shields.io/badge/Riverpod-State%20Management-00B4D8?style=for-the-badge)](https://riverpod.dev/)

> Part of the [Stockx Platform](../README.md). Also see the [Backend README](../backend/README.md).

---

## Overview

This directory contains the Flutter web application that serves as the user-facing interface for Stockx. The dashboard provides two distinct interaction modes that operate in parallel:

**Manual CRUD Mode (Pathway A):** Six data grid views — one for each database table — allow administrators to browse, create, update, and delete records. These views call the Gilhari REST API directly (routed through the FastAPI proxy at `/api/gilhari/`) using standard HTTP requests. No AI is involved in this pathway.

**AI Analytics Mode (Pathway B):** A dedicated chat panel accepts natural language queries. Messages are sent to the FastAPI agentic backend at `/api/agentic-chat`, which runs the LangGraph agent loop and streams back a structured `AgentResponse` JSON payload. The frontend parses the `response_type` field and renders the appropriate Generative UI widget inline within the chat conversation.

---

## Prerequisites

- Flutter SDK 3.x or later (with Dart SDK 3.x)
- Chrome browser (required for `--web-browser-flag` CORS bypass during local development)
- The FastAPI backend must be running on port `8001` before launching the dashboard

---

## Running Locally

```cmd
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

The `--disable-web-security` flag is required during local development to prevent CORS errors when the Flutter app in Chrome calls `localhost:8001`. In a production deployment behind a reverse proxy, this flag is not needed.

---

## Directory Structure

```
admin_dashboard/
├── lib/
│   ├── main.dart                    # App entry point; wires up Riverpod and theming
│   ├── models/                      # Dart data classes for all six Stockx entities
│   ├── providers/                   # Riverpod state providers
│   ├── services/                    # HTTP service layer (Gilhari API calls, agent chat)
│   ├── theme/                       # App-wide color palette, text styles, and Material theme
│   └── ui/
│       ├── components/              # Reusable UI widgets
│       │   ├── dynamic_message_widget.dart   # Generative UI renderer (all response types)
│       │   ├── async_data_grid.dart          # Reusable paginated data grid
│       │   ├── base_modal.dart              # Shared modal dialog base
│       │   ├── foreign_key_autocomplete.dart # FK lookup input widget
│       │   ├── inventory_item_form.dart      # Create/edit form for InventoryItems
│       │   ├── item_category_form.dart       # Create/edit form for ItemCategories
│       │   ├── purchase_order_form.dart      # Create/edit form for PurchaseOrders (with line items)
│       │   ├── purchase_order_item_form.dart # Create/edit form for PurchaseOrderItems
│       │   ├── stock_transaction_form.dart   # Create/edit form for StockTransactions
│       │   └── supplier_form.dart           # Create/edit form for Suppliers
│       ├── layout/                  # App shell, sidebar navigation, and responsive layout
│       └── views/                   # Top-level page views
│           ├── agent_chat_view.dart          # AI Analytics chat panel
│           ├── auth_view.dart               # Password entry screen
│           ├── inventory_items_view.dart     # InventoryItems CRUD grid
│           ├── item_categories_view.dart     # ItemCategories CRUD grid
│           ├── purchase_order_items_view.dart # PurchaseOrderItems CRUD grid
│           ├── purchase_orders_view.dart     # PurchaseOrders CRUD grid
│           ├── stock_transactions_view.dart  # StockTransactions CRUD grid
│           └── suppliers_view.dart          # Suppliers CRUD grid
├── assets/
│   └── world_map.svg                # SVG world map asset for the regional_view widget
├── web/                             # Flutter web entry files (index.html, manifest)
└── pubspec.yaml                     # Package manifest and dependency declarations
```

---

## Application Flow

### Authentication

On first launch, the app displays `auth_view.dart`, which prompts the user for the application password. The password is submitted to `GET /api/auth/verify` on the backend. On success, it is stored in `SharedPreferences` and reused for all subsequent API calls via the `X-App-Password` request header.

### Navigation and Layout

The app uses a persistent left sidebar for navigation. Each item in the sidebar routes to one of the six CRUD views or the AI Analytics view. The active view is managed by a Riverpod state provider in the `providers/` directory.

### Manual CRUD Views

Each of the six CRUD views follows the same structural pattern:

1. An `AsyncDataGrid` widget renders the entity records as a paginated table.
2. A toolbar provides add, edit, and delete actions.
3. Selecting edit or add opens the corresponding form widget (e.g., `InventoryItemForm`) inside a `BaseModal` dialog.
4. Form submissions dispatch HTTP requests (POST / PUT / DELETE) to the Gilhari REST API via the FastAPI proxy.

The `PurchaseOrderForm` is the most complex, as it manages a nested list of `PurchaseOrderItems` that are created or modified alongside the parent order in a single coordinated sequence of API calls.

### AI Analytics View

The `agent_chat_view.dart` maintains a scrollable list of chat messages. Each user message triggers:

1. An HTTP POST to `/api/agentic-chat` with the message text and the `X-App-Password` header.
2. The response is read as a streaming NDJSON body.
3. Status update lines (e.g., "Calling tool: query_InventoryItems...") are parsed and displayed as intermediate progress indicators.
4. The final line of the stream is parsed as an `AgentResponse` JSON object.
5. A `DynamicMessageWidget` is instantiated with the parsed response and appended to the message list.

---

## Generative UI Widget System

`dynamic_message_widget.dart` is the core of the Generative UI system. It is a single widget that reads the `response_type` field of an `AgentResponse` and renders one of the following sub-widgets:

| Response Type | Widget Rendered |
|---|---|
| `text_only` | `MarkdownBody` via `flutter_markdown` |
| `table_view` | Scrollable `DataTable` with alternating row colors |
| `direct_fetch_table` | `AsyncDataGrid` that fetches data live from Gilhari using the class name and filter in the payload |
| `metric_kpi_view` | A horizontal row of KPI summary cards, each with a title, value, trend icon, and color accent |
| `chart_view` | A `BarChart`, `PieChart`, or `LineChart` rendered via the `fl_chart` package |
| `timeline_view` | A vertical timeline with icon, timestamp, title, and subtitle per entry |
| `kanban_view` | A horizontally scrollable multi-column board with draggable-style color-coded cards |
| `regional_view` | An `SvgPicture` of the world map SVG with overlaid regional data labels |
| `actionable_form_view` | A dynamic form with typed fields; on submit, creates a `confirmation_view` for the user to review before execution |
| `alert_anomaly_view` | A list of severity-badged alert cards |
| `confirmation_view` | A confirmation card with a summary and a Confirm button that calls `POST /api/execute-tool` |

---

## State Management

The app uses **Riverpod** (`flutter_riverpod`) for state management. Key providers include:

- **Navigation provider** — tracks the currently active sidebar tab and selected view
- **Auth provider** — stores the verified password and authentication status in `SharedPreferences`
- **Chat provider** — manages the list of chat messages in the AI Analytics view
- **Data providers** — per-entity providers that hold the fetched record lists and loading/error states for each CRUD view

---

## Theming and Design

All colors, typography, and component styles are defined centrally in `lib/theme/`. The app uses:

- **Google Fonts** (`google_fonts` package) for consistent, high-quality typography
- A dark-mode-first design with a slate-based primary palette and accent colors per entity type
- Smooth animated state transitions in the chat panel and data grids
- Responsive layout rules in the sidebar to collapse gracefully at narrower viewport widths

---

## Key Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | ^3.3.2 | Reactive state management |
| `fl_chart` | ^1.2.0 | Bar, pie, and line chart rendering |
| `flutter_markdown` | ^0.7.7 | Markdown rendering for `text_only` agent responses |
| `flutter_svg` | ^2.3.0 | SVG world map rendering for `regional_view` |
| `google_fonts` | ^8.1.0 | Typography |
| `http` | ^1.6.0 | HTTP client for all API calls |
| `shared_preferences` | ^2.5.5 | Persistent local storage for authentication credentials |

---

## CORS and Local Development

During local development, the Flutter web app runs in a Chrome instance where all `localhost` cross-origin calls would otherwise be blocked by CORS headers. The `--disable-web-security` flag bypasses this restriction.

In a production deployment, the FastAPI backend should be configured with explicit CORS middleware (`fastapi.middleware.cors.CORSMiddleware`) pointing to the deployed frontend origin, and this flag should not be used.

---

## Building for Production

To compile the Flutter app for deployment as static web assets:
```cmd
flutter build web --release
```

The compiled output will be in `build/web/`. Serve it using any static file host (Nginx, Firebase Hosting, GitHub Pages, etc.) and point the API base URL environment to your deployed FastAPI backend.

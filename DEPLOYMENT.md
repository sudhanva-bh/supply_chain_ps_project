# Stockx Complete Azure Deployment Guide

This document records the exact steps taken to deploy the Stockx Agentic Supply Chain platform from a local Docker setup to a full serverless **Azure Cloud** infrastructure.

---

## 🌐 Live Deployments

- **Admin Dashboard (Flutter Frontend):** [https://thankful-water-0f80cc410.7.azurestaticapps.net/](https://thankful-water-0f80cc410.7.azurestaticapps.net/)
- **AI Agent API (Python Backend):** [https://supply-chain-agentic-1234.azurewebsites.net/docs](https://supply-chain-agentic-1234.azurewebsites.net/docs)
- **Gilhari Microservice (REST API):** `https://gilhari-service-app.orangesand-d052af28.southindia.azurecontainerapps.io`

---

## 🏗️ Architecture Overview

The production deployment utilizes four primary Microsoft Azure PaaS components:
1. **Azure SQL Database:** Hosts the 6-table normalized relational schema.
2. **Azure Container Apps:** Runs the Gilhari ORM Docker Microservice.
3. **Azure App Service (Linux):** Hosts the Python FastAPI + LangGraph Agent.
4. **Azure Static Web Apps:** Hosts the Flutter Web Administrative Dashboard.

---

## 1. Database: Azure SQL Database

### Creation
- Created an **Azure SQL Database** (Basic Tier) via the Azure Portal.
- Configured the SQL server firewall to allow "Azure Services and resources to access this server" and explicitly allowed public IP access for the initial seed.
- **Connection String Format:** `Driver={ODBC Driver 18 for SQL Server};Server=tcp:<SERVER>.database.windows.net,1433;Database=<DB>;Uid=<USER>;Pwd=<PASS>;Encrypt=yes;`

### Initialization
Instead of running SQL scripts locally via `sqlcmd`, the database was initialized remotely using a Python script:
```powershell
python init_azure_db.py
```
This script reads the `.env` credentials, connects via `pyodbc`, and executes `sql/init.sql`.

---

## 2. Microservice: Azure Container Apps (Gilhari)

### Container Registry
We pushed the compiled Gilhari container to an Azure Container Registry (ACR) to securely host the image:
```powershell
az acr login --name StockxRegistry
docker tag supply_chain_service_cloud stockxregistry.azurecr.io/gilhari-service:latest
docker push stockxregistry.azurecr.io/gilhari-service:latest
```

### Container App Creation
- Created an **Azure Container App** (Consumption plan, 0.5 CPU cores, 1 Gi Memory).
- Configured the image source to point to our private `StockxRegistry`.
- Set Ingress settings to accept traffic from anywhere on **Port 80**.
- **Crucial Note:** Ensure the container has the `config/supply_chain.jdx` properly injected via Dockerfile or volume mounts, pointing directly to the Azure SQL Server hostname.

---

## 3. AI Agent: Azure App Service (Python Backend)

### Infrastructure Setup
Created a Free Tier (F1) App Service Plan for Linux:
```powershell
az appservice plan create --name SupplyChainPlan --resource-group SupplyChainBackend --sku F1 --is-linux
az webapp create --resource-group SupplyChainBackend --plan SupplyChainPlan --name <YourAppName> --runtime "PYTHON:3.11"
```

### Startup Configuration
Because Azure looks for `app.py` by default, we explicitly configured the startup command for our `main.py` FastAPI app:
```powershell
az webapp config set --resource-group SupplyChainBackend --name <YourAppName> --startup-file "python -m uvicorn main:app --host 0.0.0.0"
```

### CORS & Security
To allow the Flutter frontend (hosted on a different domain) to communicate with the API, `CORSMiddleware` was added to `backend/main.py`.

### Zip Deployment
We compressed the backend directory (excluding `.venv` to save space) and deployed it directly:
```powershell
az webapp deployment source config-zip --resource-group SupplyChainBackend --name <YourAppName> --src backend.zip
```
*(Azure automatically executes the Oryx build engine to install `requirements.txt` upon receiving the zip).*

---

## 4. Frontend: Azure Static Web Apps (Flutter)

### Initial Creation
- In the Azure Portal, created an **Azure Static Web App**.
- Selected the **GitHub** deployment source and connected the `main` branch.
- Selected the **Custom** Build Preset with:
  - App location: `/admin_dashboard`
  - Output location: `build/web`

### GitHub Action Configuration
Azure's default Oryx builder does not support Flutter natively. We resolved this by modifying the auto-generated `.github/workflows/azure-static-web-apps-*.yml` file.

We injected a Flutter installation step, manually ran `flutter build web`, and instructed Azure to skip its own internal build phase:
```yaml
    steps:
      - uses: actions/checkout@v3
        with:
          submodules: true
          lfs: false
          
      - name: Install Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          
      - name: Build Flutter App
        run: |
          cd admin_dashboard
          flutter pub get
          flutter build web
          
      - name: Build And Deploy
        id: builddeploy
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN_... }}
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          action: "upload"
          app_location: "/admin_dashboard"
          output_location: "build/web"
          skip_app_build: true
```

### Continuous Integration
Every subsequent push to the `main` branch automatically triggers this GitHub action, rebuilding the Flutter app and deploying it seamlessly.

---

## 5. Operations & Maintenance Sheet

Here are the most common commands you'll need to maintain and update the deployed platform.

### Frontend (Admin Dashboard)
The frontend is configured with GitHub Actions. To redeploy, simply push your changes to the `main` branch.
```bash
git add admin_dashboard/
git commit -m "Update frontend"
git push origin main
```
To monitor the deployment, check the Actions tab in your GitHub repository.

### Backend (Python AI Agent)
To deploy changes made in the `backend/` directory to Azure App Service:
```powershell
# 1. Package the code (excluding virtual environments)
if (Test-Path backend.zip) { Remove-Item backend.zip }
Get-ChildItem -Path backend -Exclude ".venv", "__pycache__", ".git", "*.log" | Compress-Archive -DestinationPath backend.zip -Force

# 2. Deploy the zip to Azure
az webapp deploy --resource-group SupplyChainBackend --name supply-chain-agentic-1234 --src-path backend.zip --type zip
```

**Helpful Backend Commands:**
- **Update Env Var:** `az webapp config appsettings set --resource-group SupplyChainBackend --name supply-chain-agentic-1234 --settings "KEY=VALUE"`
- **Restart App:** `az webapp restart --resource-group SupplyChainBackend --name supply-chain-agentic-1234`
- **Tail Logs:** `az webapp log tail --resource-group SupplyChainBackend --name supply-chain-agentic-1234`

### Gilhari Microservice
To update the underlying Gilhari container (for example, if the JDX schema changes):
```powershell
# 1. Build and push the new image
docker build -t bhsudhanva/supply-chain-gilhari:latest -f Dockerfile .
docker push bhsudhanva/supply-chain-gilhari:latest

# 2. Instruct Azure Container Apps to pull and redeploy the new image
az containerapp update --name gilhari-service-app --resource-group SupplyChainBackend --image bhsudhanva/supply-chain-gilhari:latest
```

**Helpful Gilhari Commands:**
- **View Logs:** `az containerapp logs show -n gilhari-service-app -g SupplyChainBackend`

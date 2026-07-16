# Cloud Deployment Plan (Azure)

This document outlines the step-by-step process for deploying the AI Supply Chain project to Microsoft Azure, fulfilling the requirements for **Project 23: Developing an AI Agent with OpenAI Agents SDK that Uses ORMCP to Access Relational Data on Cloud**.

The architecture uses Azure's free/student tiers to minimize costs while fully meeting the project rubric:
- **Database**: Azure SQL Database
- **Gilhari ORMCP Service**: Azure Container Apps (Dockerized microservice)
- **AI Agent Backend (Python)**: Azure App Service
- **Frontend Dashboard (Flutter)**: Azure Static Web Apps

---

## Step 1: Provision the Cloud Database (Azure SQL)
Running MS SQL Server in a Docker container on the cloud requires significant compute resources. Instead, we will use a managed cloud database.

1. **Create Resource**: Go to the Azure Portal and search for **Azure SQL**.
2. **Select Database**: Click **Create** under "SQL databases" (Single database).
3. **Free Tier**: On the Basics tab, look for the **"Apply Free Offer"** banner and click it. This grants 100,000 vCore seconds and 32GB of data per month.
4. **Configuration**:
   - Create a new Resource Group (e.g., `supply-chain-ai-rg`).
   - Create a new Server.
   - For Authentication, select **"Use SQL authentication"**. Create a server admin login and password.
   - On the Networking tab, under Firewall rules, select **"Allow Azure services and resources to access this server" = Yes**. Also add your current client IP address so you can seed the database locally.
5. **Update Code**: Once deployed, retrieve the server name (e.g., `myserver.database.windows.net`). We will update `config/supply_chain.jdx` and `backend/.env` with this new connection string.
6. **Seed Data**: Run the `seed.py` script locally to populate the Azure SQL database.

---

## Step 2: Deploy the Gilhari ORMCP Microservice (Azure Container Apps)
The rubric requires a *Dockerized Gilhari microservice on the cloud*. 

1. **Create a Container Registry (ACR)**:
   - In Azure, create an **Azure Container Registry** (Basic tier).
   - Login to the registry via Azure CLI (`az acr login --name <RegistryName>`).
2. **Build and Push the Image**:
   - From the project root, build the Gilhari Docker image:
     ```bash
     docker build -t <RegistryName>.azurecr.io/gilhari-service:latest .
     ```
   - Push the image to Azure:
     ```bash
     docker push <RegistryName>.azurecr.io/gilhari-service:latest
     ```
3. **Deploy to Azure Container Apps**:
   - In Azure, create a new **Container App**.
   - Choose the image from your ACR.
   - Set the ingress to accept HTTP traffic on port `8081` (the port Gilhari runs on).
   - *Note: Container Apps has a generous free grant of 180,000 vCPU seconds per month.*

---

## Step 3: Deploy the AI Agent Backend (Azure App Service)
The Python backend uses the OpenAI Agents SDK and MCP to communicate with Gilhari.

1. **Modify the Code**: 
   - Update `backend/main.py` so that the Gilhari proxy URL points to your new Azure Container App URL instead of `127.0.0.1`. (We will use an environment variable `GILHARI_URL` for this).
2. **Create the App Service**:
   - In Azure, create a **Web App**.
   - Publish: **Code**.
   - Runtime stack: **Python 3.11**.
   - Operating System: **Linux**.
   - Pricing Plan: **Free F1** (1 GB memory).
3. **Configure Environment Variables**:
   - In the App Service configuration, add your `OPENAI_API_KEY` (or `GEMINI_API_KEY`) and `APP_PASSWORD`.
4. **Deploy**:
   - You can deploy the `backend/` folder via the Azure VS Code extension or using the Azure CLI (`az webapp up`).

---

## Step 4: Deploy the Frontend Dashboard (Azure Static Web Apps)
1. **Create the Resource**:
   - In Azure, create a **Static Web App**.
   - Plan type: **Free**.
2. **Link to GitHub**:
   - Connect your GitHub repository.
3. **Configure Build Details**:
   - Build Presets: **Flutter**.
   - App location: `/admin_dashboard`.
   - Output location: `build/web`.
4. **Update Frontend Code**:
   - Ensure the Flutter app's API endpoints point to your deployed Python App Service URL instead of localhost.

---

## Step 5: Final Verification & Documentation
1. **Test the System**: Open the live Flutter dashboard, log in with your app password, and interact with the AI agent to verify it successfully pulls data from the Azure SQL Database via the deployed Gilhari MCP service.
2. **Update README.md**: Ensure the project README highlights the Azure cloud deployment, the use of Dockerized Gilhari, MS SQL Server, and the OpenAI Agents SDK to satisfy the grading rubric.
3. **Commit and Push**: Push all final configuration changes and documentation to GitHub.

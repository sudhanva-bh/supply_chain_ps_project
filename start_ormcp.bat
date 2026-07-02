@echo off
set GILHARI_BASE_URL=http://localhost:80/gilhari/v1/
set MCP_SERVER_NAME=SupplyChainMCP

if not exist .venv (
    python -m venv .venv --system-site-packages
)
call .venv\Scripts\activate.bat

:: Install ormcp-server if not already available in the environment
pip show ormcp-server >nul 2>&1
if errorlevel 1 (
    echo Installing ormcp-server...
    pip install ormcp-server
) else (
    echo ormcp-server is already available in this environment.
)

python -m ormcp_server

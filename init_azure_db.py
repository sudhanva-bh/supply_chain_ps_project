import os
import pyodbc
from dotenv import load_dotenv

load_dotenv('backend/.env')

server = os.environ.get("AZURE_SQL_SERVER")
database = os.environ.get("AZURE_SQL_DATABASE")
username = os.environ.get("AZURE_SQL_USER")
password = os.environ.get("AZURE_SQL_PASSWORD")

print(f"Connecting to {server}...")

try:
    drivers = [d for d in pyodbc.drivers() if 'SQL Server' in d]
    driver = '{ODBC Driver 18 for SQL Server}' if 'ODBC Driver 18 for SQL Server' in drivers else (
        '{ODBC Driver 17 for SQL Server}' if 'ODBC Driver 17 for SQL Server' in drivers else '{' + drivers[-1] + '}'
    )
except IndexError:
    print("Error: No ODBC Driver for SQL Server found on your system.")
    exit(1)

conn_str = f"DRIVER={driver};SERVER={server};DATABASE={database};UID={username};PWD={password};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"

try:
    with pyodbc.connect(conn_str) as conn:
        conn.autocommit = True
        cursor = conn.cursor()
        
        with open('sql/init.sql', 'r') as f:
            sql_script = f.read()
            
        # Remove CREATE DATABASE and USE statements as they are not supported in Azure SQL batches
        commands = sql_script.split('GO')
        for cmd in commands:
            cmd = cmd.strip()
            if not cmd or cmd.upper().startswith('CREATE DATABASE') or cmd.upper().startswith('USE '):
                continue
            print(f"Executing batch:\n{cmd[:100]}...")
            cursor.execute(cmd)
            
        print("Database schema successfully created on Azure SQL!")
except Exception as e:
    print(f"Failed: {e}")

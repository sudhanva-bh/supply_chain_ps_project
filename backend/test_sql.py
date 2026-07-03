import asyncio
import sys

async def main():
    sql_q = "SELECT TOP 5 s.companyName, SUM(poi.quantityOrdered) as totalVol FROM Suppliers s JOIN InventoryItems i ON s.supplierID = i.supplierID JOIN PurchaseOrderItems poi ON i.itemID = poi.itemID GROUP BY s.companyName ORDER BY totalVol DESC"
    proc = await asyncio.create_subprocess_exec(
        "docker", "exec", "-i", "sqlserver", 
        "/opt/mssql-tools18/bin/sqlcmd", "-S", "localhost", 
        "-U", "sa", "-P", "YourStrong!Passw0rd", "-C", 
        "-d", "supply_chain_db", "-Q", sql_q, "-s", ",", "-W",
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    stdout, stderr = await proc.communicate()
    print("RETURN CODE:", proc.returncode)
    print("STDOUT:", stdout.decode().strip())
    print("STDERR:", stderr.decode().strip())

if __name__ == "__main__":
    asyncio.run(main())

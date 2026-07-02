import requests
import json
import random
import subprocess
import concurrent.futures
from datetime import datetime, timedelta

BASE_URL = "http://localhost/gilhari/v1/"

def truncate_tables():
    print("Truncating existing tables via SQL...")
    sql_command = """
    USE supply_chain_db;
    DELETE FROM StockTransactions;
    DELETE FROM PurchaseOrderItems;
    DELETE FROM PurchaseOrders;
    DELETE FROM InventoryItems;
    DELETE FROM ItemCategories;
    DELETE FROM Suppliers;
    """
    try:
        subprocess.run([
            "docker", "exec", "-i", "sqlserver", 
            "/opt/mssql-tools18/bin/sqlcmd", "-S", "localhost", "-U", "sa", "-P", "YourStrong!Passw0rd", "-C", "-Q", sql_command
        ], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        print("Tables truncated successfully.\n")
    except subprocess.CalledProcessError as e:
        print("Failed to truncate tables. Is the 'sqlserver' container running?")
        print(e.stderr.decode())

# Realistic Data Pools
SUPPLIER_NAMES = [
    "TechSource Logistics", "Global ElectroParts", "Nova Electronics", "Apex Hardware Solutions", 
    "Zenith Computing", "Quantum Circuits Inc", "Pioneer Silicon", "Nexus Component Co", 
    "Omega Systems", "Prime Tech Supply", "Stellar Components", "Vertex Technologies",
    "BlueWave Electronics", "Summit Hardware", "Horizon Tech Distributors"
]
REGIONS = ["North America", "Europe", "Asia-Pacific", "South America", "Middle East", "Africa"]

CATEGORY_DATA = [
    ("Processors", "Central Processing Units (CPUs) for servers and desktops"),
    ("Motherboards", "Main circuit boards for various form factors"),
    ("Memory", "RAM modules (DDR4, DDR5)"),
    ("Storage", "Solid State Drives and Hard Disk Drives"),
    ("Graphics Cards", "GPUs for rendering and compute"),
    ("Power Supplies", "ATX and SFX Power Supply Units"),
    ("Cooling", "Liquid coolers and case fans"),
    ("Networking", "Routers, switches, and network cards"),
    ("Peripherals", "Keyboards, mice, and accessories"),
    ("Displays", "Monitors and display panels")
]

BRANDS = ["Corsair", "ASUS", "MSI", "Gigabyte", "Intel", "AMD", "NVIDIA", "Samsung", "Western Digital", "Seagate", "Logitech", "Razer", "NZXT", "EVGA", "Noctua", "Crucial", "Kingston"]
ADJECTIVES = ["High-Performance", "Ultra-Fast", "Premium", "Budget", "Enterprise", "Gaming", "Compact", "Advanced", "Silent", "RGB", "Pro", "Elite"]
NOUNS = {
    "Processors": ["Core CPU", "Ryzen Processor", "Xeon Chip", "EPYC Server CPU", "ARM Processor"],
    "Motherboards": ["Z-Series Motherboard", "B-Series Board", "X-Series Motherboard", "Mini-ITX Board", "E-ATX Server Board"],
    "Memory": ["16GB RAM Kit", "32GB RAM Kit", "64GB ECC Memory", "8GB SODIMM", "128GB Server Memory"],
    "Storage": ["1TB NVMe SSD", "2TB NVMe SSD", "4TB SATA SSD", "8TB HDD", "16TB Enterprise HDD"],
    "Graphics Cards": ["RTX 4090 GPU", "RX 7900 XT GPU", "RTX 4070 Ti", "Pro Workstation GPU", "AI Compute Accelerator"],
    "Power Supplies": ["750W Gold PSU", "850W Platinum PSU", "1000W Titanium PSU", "SFX 600W PSU", "1600W Server PSU"],
    "Cooling": ["360mm AIO Liquid Cooler", "240mm AIO Cooler", "120mm Case Fan", "Dual-Tower Air Cooler", "Server Rack Fan"],
    "Networking": ["WiFi 6E Router", "10GbE Network Card", "24-Port Gigabit Switch", "Fiber Transceiver", "Mesh WiFi Node"],
    "Peripherals": ["Mechanical Keyboard", "Wireless Gaming Mouse", "Studio Microphone", "HD Webcam", "Ergonomic Wrist Rest"],
    "Displays": ["27-inch 4K Monitor", "34-inch Ultrawide Display", "24-inch 1080p Monitor", "32-inch 1440p Monitor", "Portable USB-C Display"]
}

# Generate Random IDs to avoid collision with init.sql
def gen_id():
    return random.randint(100000, 999999)

# Generate Random Data
suppliers = []
supplier_ids = []
for name in SUPPLIER_NAMES:
    for i in range(3): # 45 suppliers total
        sid = gen_id()
        supplier_ids.append(sid)
        suppliers.append({
            "supplierID": sid,
            "companyName": f"{name} {random.choice(['LLC', 'Inc.', 'Corp.', 'Ltd', 'Group'])}",
            "contactEmail": f"sales@{name.lower().replace(' ', '')}.com",
            "region": random.choice(REGIONS)
        })

categories = []
category_ids = []
category_name_to_id = {}
for cat_name, desc in CATEGORY_DATA:
    cid = gen_id()
    category_ids.append(cid)
    category_name_to_id[cat_name] = cid
    categories.append({
        "categoryID": cid,
        "categoryName": cat_name,
        "description": desc
    })

items = []
item_ids = []
for i in range(1000):
    iid = gen_id()
    item_ids.append(iid)
    
    # Pick random category to match the noun
    cat_name = random.choice(list(NOUNS.keys()))
    cat_id = category_name_to_id[cat_name]
    
    brand = random.choice(BRANDS)
    adj = random.choice(ADJECTIVES)
    noun = random.choice(NOUNS[cat_name])
    product_name = f"{brand} {adj} {noun} {random.randint(100, 9999)}"
    
    items.append({
        "itemID": iid,
        "name": product_name,
        "stockQuantity": random.randint(0, 1000),
        "unitPrice": round(random.uniform(15.0, 2500.0), 2),
        "categoryID": cat_id,
        "supplierID": random.choice(supplier_ids)
    })

orders = []
order_ids = []
for i in range(333):
    oid = gen_id()
    order_ids.append(oid)
    orders.append({
        "orderID": oid,
        "orderDate": (datetime.now() - timedelta(days=random.randint(1, 365))).strftime("%Y-%m-%dT%H:%M:%S"),
        "totalCost": round(random.uniform(500.0, 50000.0), 2),
        "deliveryStatus": random.choice(["PENDING", "IN_TRANSIT", "DELIVERED", "CANCELLED", "PROCESSING"])
    })

order_items = []
for i in range(1000):
    order_items.append({
        "orderItemID": gen_id(),
        "orderID": random.choice(order_ids),
        "itemID": random.choice(item_ids),
        "quantityOrdered": random.randint(1, 150),
        "negotiatedPrice": round(random.uniform(10.0, 2300.0), 2)
    })

transactions = []
for i in range(1666):
    transactions.append({
        "transactionID": gen_id(),
        "itemID": random.choice(item_ids),
        "quantityChanged": random.choice([random.randint(10, 200), random.randint(-50, -1)]),
        "transactionType": random.choice(["RESTOCK", "SALE", "ADJUSTMENT", "RETURN", "DAMAGE_WRITE_OFF"]),
        "timestamp": (datetime.now() - timedelta(days=random.randint(1, 365))).strftime("%Y-%m-%dT%H:%M:%S")
    })

def post_single(url, item, headers):
    payload = {"entity": item}
    try:
        response = requests.post(url, headers=headers, data=json.dumps(payload))
        if response.status_code in (200, 201):
            return True
        else:
            return False
    except:
        return False

def post_data(endpoint, data):
    url = BASE_URL + endpoint
    print(f"Seeding {endpoint} ({len(data)} records)...")
    headers = {'Content-Type': 'application/json'}
    
    success_count = 0
    # Use ThreadPoolExecutor to speed up insertion of thousands of records
    with concurrent.futures.ThreadPoolExecutor(max_workers=20) as executor:
        futures = [executor.submit(post_single, url, item, headers) for item in data]
        for future in concurrent.futures.as_completed(futures):
            if future.result():
                success_count += 1
            
    print(f"Successfully inserted {success_count} / {len(data)} into {endpoint}.\n")

if __name__ == "__main__":
    print("Starting Seeding Process via Gilhari REST API...\n")
    truncate_tables()
    
    post_data("Supplier", suppliers)
    post_data("ItemCategory", categories)
    post_data("InventoryItem", items)
    post_data("PurchaseOrder", orders)
    post_data("PurchaseOrderItem", order_items)
    post_data("StockTransaction", transactions)

    print("Seeding completed!")

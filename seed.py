import requests
import json
import random
from datetime import datetime, timedelta

BASE_URL = "http://localhost/gilhari/v1/"

# Generate Random IDs to avoid collision with init.sql
def gen_id():
    return random.randint(10000, 99999)

# Generate Random Data
suppliers = []
supplier_ids = []
for i in range(5):
    sid = gen_id()
    supplier_ids.append(sid)
    suppliers.append({
        "supplierID": sid,
        "companyName": f"Random Supplier {sid} Inc.",
        "contactEmail": f"contact{sid}@supplier.com",
        "region": random.choice(["North America", "Europe", "Asia-Pacific", "South America"])
    })

categories = []
category_ids = []
for i in range(3):
    cid = gen_id()
    category_ids.append(cid)
    categories.append({
        "categoryID": cid,
        "categoryName": f"Category {cid}",
        "description": "Auto-generated category"
    })

items = []
item_ids = []
for i in range(10):
    iid = gen_id()
    item_ids.append(iid)
    items.append({
        "itemID": iid,
        "name": f"Random Item {iid}",
        "stockQuantity": random.randint(10, 500),
        "unitPrice": round(random.uniform(10.0, 500.0), 2),
        "categoryID": random.choice(category_ids),
        "supplierID": random.choice(supplier_ids)
    })

orders = []
order_ids = []
for i in range(5):
    oid = gen_id()
    order_ids.append(oid)
    orders.append({
        "orderID": oid,
        "orderDate": (datetime.now() - timedelta(days=random.randint(1, 30))).strftime("%Y-%m-%dT%H:%M:%S"),
        "totalCost": round(random.uniform(1000.0, 5000.0), 2),
        "deliveryStatus": random.choice(["PENDING", "IN_TRANSIT", "DELIVERED"])
    })

order_items = []
for i in range(10):
    order_items.append({
        "orderItemID": gen_id(),
        "orderID": random.choice(order_ids),
        "itemID": random.choice(item_ids),
        "quantityOrdered": random.randint(5, 50),
        "negotiatedPrice": round(random.uniform(10.0, 450.0), 2)
    })

transactions = []
for i in range(15):
    transactions.append({
        "transactionID": gen_id(),
        "itemID": random.choice(item_ids),
        "quantityChanged": random.randint(-50, 50),
        "transactionType": random.choice(["RESTOCK", "SALE", "ADJUSTMENT"]),
        "timestamp": (datetime.now() - timedelta(days=random.randint(1, 10))).strftime("%Y-%m-%dT%H:%M:%S")
    })

def post_data(endpoint, data):
    url = BASE_URL + endpoint
    print(f"Seeding {endpoint} ({len(data)} records)...")
    headers = {'Content-Type': 'application/json'}
    
    success_count = 0
    for item in data:
        payload = {"entity": item}
        try:
            response = requests.post(url, headers=headers, data=json.dumps(payload))
            if response.status_code in (200, 201):
                success_count += 1
            else:
                print(f"Failed to insert into {endpoint}: {response.status_code} - {response.text}")
        except Exception as e:
            print(f"Error posting to {endpoint}: {e}")
            
    print(f"Successfully inserted {success_count} / {len(data)} into {endpoint}.\n")

print("Starting Seeding Process via Gilhari REST API...\n")

post_data("Supplier", suppliers)
post_data("ItemCategory", categories)
post_data("InventoryItem", items)
post_data("PurchaseOrder", orders)
post_data("PurchaseOrderItem", order_items)
post_data("StockTransaction", transactions)

print("Seeding completed!")

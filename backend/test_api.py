import urllib.request
import urllib.error
import json

url = 'http://localhost:8003/api/agentic-chat'
data = json.dumps({"message": "Hello"}).encode('utf-8')
req = urllib.request.Request(url, data=data, headers={'Content-Type': 'application/json', 'X-App-Password': 'secret123'})

try:
    with urllib.request.urlopen(req) as f:
        print(f.read().decode())
except urllib.error.HTTPError as e:
    print(f"HTTPError: {e.code}")
    print(e.read().decode())

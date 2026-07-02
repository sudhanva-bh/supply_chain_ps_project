import subprocess
import json
import threading
import sys
import time
import os

def read_responses(proc, responses):
    for line in iter(proc.stdout.readline, b''):
        if line:
            try:
                data = json.loads(line.decode('utf-8').strip())
                responses.append(data)
                print("Received response with id:", data.get("id", "notification"))
            except json.JSONDecodeError:
                pass

def read_stderr(proc):
    for line in iter(proc.stderr.readline, b''):
        if line:
            print("SERVER STDERR:", line.decode('utf-8').strip())

def main():
    print("Starting ORMCP server via start_ormcp.bat...")
    env = os.environ.copy()
    env["PYTHONUNBUFFERED"] = "1"
    
    proc = subprocess.Popen(
        ["cmd.exe", "/c", "start_ormcp.bat"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=env
    )
    
    responses = []
    t1 = threading.Thread(target=read_responses, args=(proc, responses))
    t1.daemon = True
    t1.start()
    
    t2 = threading.Thread(target=read_stderr, args=(proc,))
    t2.daemon = True
    t2.start()
    
    print("Waiting 15 seconds for venv creation and package installation...")
    time.sleep(15)
    
    print("Sending MCP initialize request...")
    init_req = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "TestValidationClient", "version": "1.0"}
        }
    }
    proc.stdin.write((json.dumps(init_req) + "\n").encode('utf-8'))
    proc.stdin.flush()
    time.sleep(3)
    
    print("Sending notifications/initialized...")
    init_notif = {
        "jsonrpc": "2.0",
        "method": "notifications/initialized"
    }
    proc.stdin.write((json.dumps(init_notif) + "\n").encode('utf-8'))
    proc.stdin.flush()
    time.sleep(1)
    
    print("Sending tools/list request...")
    tools_req = {
        "jsonrpc": "2.0",
        "id": 2,
        "method": "tools/list"
    }
    proc.stdin.write((json.dumps(tools_req) + "\n").encode('utf-8'))
    proc.stdin.flush()
    
    time.sleep(5)
    
    log_file = 'mcp_tools_output.log'
    with open(log_file, 'w') as f:
        json.dump(responses, f, indent=2)
        
    print(f"\nSaved {len(responses)} valid JSON responses to {log_file}")
    
    # Analyze the responses to verify tools
    tools_exposed = []
    for resp in responses:
        if resp.get('id') == 2 and 'result' in resp and 'tools' in resp['result']:
            for tool in resp['result']['tools']:
                tools_exposed.append(tool['name'])
    
    if tools_exposed:
        print("\nSUCCESS: Tools exposed by the server:")
        for t_name in tools_exposed:
            print(f" - {t_name}")
    else:
        print("\nWARNING: No tools found in responses. Check mcp_tools_output.log or stderr logs.")
        
    proc.terminate()
    print("Test complete.")

if __name__ == "__main__":
    main()

import json
import sys

log_file = "c:/SoftwareTree/Gilhari-0.8.0b-SDK/examples/supply_chain_ps_project/backend/logs/log_2026-07-03.json"
try:
    with open(log_file, "r") as f:
        data = json.load(f)
    
    # Get the last query execution
    last_query = data[-1]
    
    print("QUERY:", last_query.get("query"))
    for loop_idx, loop_id in enumerate(last_query.get("loops", {})):
        loop = last_query["loops"][loop_id]
        print(f"\n--- LOOP {loop_idx + 1} ---")
        for tool_call in loop.get("tool_calls", []):
            name = tool_call.get("tool_name")
            print("TOOL CALLED:", name)
            if name == "execute_raw_sql":
                print("ARGS:", tool_call.get("args"))
                print("RESULT:", tool_call.get("result"))
                print("-" * 20)
                
except Exception as e:
    print("Error:", e)

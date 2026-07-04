import sys

filepath = r'c:\SoftwareTree\Gilhari-0.8.0b-SDK\examples\supply_chain_ps_project\backend\agent.py'
with open(filepath, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
in_process_chat_message = False
past_query_logger = False

for i, line in enumerate(lines):
    if '"total_cost_usd": 0.0' in line:
        new_lines.append(line.replace('0.0', '0.0,'))
        new_lines.append('            "error": None\n')
        continue
        
    if line.startswith('async def process_chat_message'):
        new_lines.append(line)
        in_process_chat_message = True
        continue
        
    if in_process_chat_message:
        if line.strip() == 'query_logger = QueryLogger(user_message, MODEL_NAME)':
            new_lines.append(line)
            new_lines.append('    \n')
            new_lines.append('    try:\n')
            past_query_logger = True
            continue
            
        if line.strip() == 'query_logger.save()':
            # Skip all query_logger.save() since it will be in finally
            continue
            
        if past_query_logger:
            # Indent by 4 spaces if it's not an empty line
            if line.strip():
                new_lines.append('    ' + line)
            else:
                new_lines.append(line)
        else:
            new_lines.append(line)
    else:
        new_lines.append(line)

# Add the except and finally block
new_lines.append('''    except Exception as e:
        import traceback
        error_msg = f"Error during agent execution: {str(e)}"
        print(f"{error_msg}\\n{traceback.format_exc()}")
        query_logger.query_log["error"] = error_msg
        import json
        yield json.dumps({"type": "status", "message": f"Fatal Error: {str(e)}"}) + "\\n"
    finally:
        query_logger.save()
''')

with open(filepath, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print("Modified agent.py successfully.")

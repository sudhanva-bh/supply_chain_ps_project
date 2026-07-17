import os
import shutil

def setup_env():
    root_env_path = ".env"
    backend_env_path = os.path.join("backend", ".env")
    
    if not os.path.exists(root_env_path):
        print(f"Error: {root_env_path} not found. Please copy .env.example to .env and configure it.")
        return

    # 1. Copy relevant variables to backend/.env
    print(f"Reading from {root_env_path}...")
    backend_vars = []
    jdbc_url = None

    with open(root_env_path, "r", encoding="utf-8") as f:
        for line in f:
            line_stripped = line.strip()
            # We want to keep everything in backend/.env except JDBC_URL which is for Gilhari container
            if line_stripped.startswith("JDBC_URL="):
                jdbc_url = line_stripped.split("=", 1)[1]
            else:
                backend_vars.append(line)

    print(f"Writing to {backend_env_path}...")
    with open(backend_env_path, "w", encoding="utf-8") as f:
        f.writelines(backend_vars)

    # 2. Generate config/supply_chain.jdx
    if not jdbc_url:
        print("Error: JDBC_URL not found in .env file.")
        return

    template_path = os.path.join("config", "supply_chain_template.txt")
    output_path = os.path.join("config", "supply_chain.jdx")

    if not os.path.exists(template_path):
        print(f"Error: Template file {template_path} not found.")
        return

    with open(template_path, 'r', encoding='utf-8') as f:
        template_content = f.read()

    new_content = template_content.replace("<JDBC_URL>", jdbc_url)

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(new_content)

    print(f"Successfully generated {output_path} from template.")
    print("Environment setup complete.")

if __name__ == "__main__":
    setup_env()

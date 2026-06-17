import sys
import json
import os

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python save_config.py <file_path> <json_string>", file=sys.stderr)
        sys.exit(1)

    file_path = sys.argv
    json_string = sys.argv

    try:
        # Ensure the directory exists
        dir_name = os.path.dirname(file_path)
        if not os.path.exists(dir_name):
            os.makedirs(dir_name)

        # Parse and write the JSON data
        data = json.loads(json_string)
        with open(file_path, 'w') as f:
            json.dump(data, f, indent=2)
        
        print(f"Config saved successfully to {file_path}")
        sys.exit(0)

    except Exception as e:
        print(f"Error saving config: {e}", file=sys.stderr)
        sys.exit(1)
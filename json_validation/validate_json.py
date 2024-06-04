import json
import sys
import subprocess
import pkg_resources
from datetime import datetime

def install_package(package):
    subprocess.check_call([sys.executable, "-m", "pip", "install", package])

def check_package_installed(package):
    try:
        dist = pkg_resources.get_distribution(package)
        return True
    except pkg_resources.DistributionNotFound:
        return False

def prompt_install_package(package):
    user_input = input(f"The package '{package}' is not installed. Would you like to install it? (y/n): ").strip().lower()
    if user_input == 'y':
        install_package(package)
    else:
        print(f"The package '{package}' is required to run this script. Exiting.")
        sys.exit(1)

def main(schema_path, json_path, save_to_file=False):
    if not check_package_installed("jsonschema"):
        prompt_install_package("jsonschema")
    
    from jsonschema import validate
    from jsonschema.exceptions import ValidationError

    # Load the JSON schema
    with open(schema_path, 'r') as schema_file:
        schema = json.load(schema_file)
    
    # Load the JSON data
    with open(json_path, 'r') as json_file:
        data = json.load(json_file)
    
    try:
        validate(instance=data, schema=schema)
        output = "Validation successful: The JSON file is valid."
        print(output)
    except ValidationError as err:
        output = f"Validation error: {err.message}"
        if save_to_file:
            current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            with open("validation_errors.txt", 'w') as error_file:
                error_file.write(f"Schema File: {schema_path}\n")
                error_file.write(f"JSON File: {json_path}\n")
                error_file.write(f"Validation Run At: {current_time}\n")
                error_file.write(output)
            print("Validation errors have been saved to validation_errors.txt")
        else:
            print(output)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python validate_json.py <schema_path> <json_path> [--save-to-file]")
        sys.exit(1)
    
    schema_path = sys.argv[1]
    json_path = sys.argv[2]
    save_to_file = "--save-to-file" in sys.argv
    
    main(schema_path, json_path, save_to_file)

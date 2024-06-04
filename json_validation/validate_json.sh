#!/bin/bash

# Bash Script: validate_json.sh

# Check if correct number of arguments is provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <schema_path> <json_path> [--save-to-file]"
    exit 1
fi

SCHEMA_PATH="$1"
JSON_PATH="$2"
SAVE_TO_FILE=false

# Check if the third parameter is the flag --save-to-file
if [ "$#" -eq 3 ] && [ "$3" == "--save-to-file" ]; then
    SAVE_TO_FILE=true
fi

# Function to check if jq is installed
check_jq_installed() {
    if ! command -v jq &> /dev/null; then
        echo "jq could not be found."
        return 1
    else
        return 0
    fi
}

# Function to install jq
install_jq() {
    echo "Installing jq..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            sudo apt-get update
            sudo apt-get install -y jq
        elif [ -f /etc/redhat-release ]; then
            sudo yum install -y epel-release
            sudo yum install -y jq
        else
            echo "Unsupported Linux distribution. Please install jq manually."
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            brew install jq
        else
            echo "Homebrew not found. Please install Homebrew and jq manually."
            exit 1
        fi
    else
        echo "Unsupported OS. Please install jq manually."
        exit 1
    fi
}

# Check if jq is installed
if ! check_jq_installed; then
    read -p "jq is not installed. Would you like to install it? (y/n): " choice
    case "$choice" in
        y|Y )
            install_jq
            ;;
        n|N )
            echo "jq is required to run this script. Exiting."
            exit 1
            ;;
        * )
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

# Function to validate JSON object
validate_object() {
    local data="$1"
    local schema="$2"
    local path="$3"
    local errors=""

    # Iterate over the properties in the schema
    for prop in $(echo "$schema" | jq -r '.properties | keys | .[]'); do
        prop_schema=$(echo "$schema" | jq -c ".properties.$prop")
        prop_value=$(echo "$data" | jq -c ".$prop")
        prop_type=$(echo "$prop_schema" | jq -r '.type')

        # Check required properties
        if [ "$(echo "$schema" | jq -r ".required | index(\"$prop\")")" != "null" ] && [ "$prop_value" == "null" ]; then
            errors="$errors\n$path/$prop is required"
            continue
        fi

        case "$prop_type" in
            "object")
                sub_errors=$(validate_object "$prop_value" "$prop_schema" "$path/$prop")
                errors="$errors$sub_errors"
                ;;
            "array")
                sub_errors=$(validate_array "$prop_value" "$prop_schema" "$path/$prop")
                errors="$errors$sub_errors"
                ;;
            "string")
                if ! [[ "$prop_value" =~ ^\".*\"$ ]]; then
                    errors="$errors\n$path/$prop should be a string"
                fi
                ;;
            "integer")
                if ! [[ "$prop_value" =~ ^[0-9]+$ ]]; then
                    errors="$errors\n$path/$prop should be an integer"
                fi
                ;;
        esac
    done

    echo -e "$errors"
}

# Function to validate JSON array
validate_array() {
    local data="$1"
    local schema="$2"
    local path="$3"
    local errors=""

    local min_items=$(echo "$schema" | jq -r '.minItems // empty')
    local max_items=$(echo "$schema" | jq -r '.maxItems // empty')

    local count=$(echo "$data" | jq '. | length')

    if [ ! -z "$min_items" ] && [ "$count" -lt "$min_items" ]; then
        errors="$errors\n$path should have at least $min_items items"
    fi
    if [ ! -z "$max_items" ] && [ "$count" -gt "$max_items" ]; then
        errors="$errors\n$path should have at most $max_items items"
    fi

    for (( i=0; i<count; i++ )); do
        local item=$(echo "$data" | jq ".[$i]")
        sub_errors=$(validate_object "$item" "$(echo "$schema" | jq '.items')" "$path[$i]")
        errors="$errors$sub_errors"
    done

    echo -e "$errors"
}

# Load the schema and JSON data
schema=$(jq -c '.' "$SCHEMA_PATH")
data=$(jq -c '.' "$JSON_PATH")

# Validate the JSON data
errors=$(validate_object "$data" "$schema" "")

if [ -z "$errors" ]; then
    output="Validation successful: The JSON file is valid."
    echo -e "$output"
else
    if [ "$SAVE_TO_FILE" == true ]; then
        current_time=$(date "+%Y-%m-%d %H:%M:%S")
        echo "Schema File: $SCHEMA_PATH" > validation_errors.txt
        echo "JSON File: $JSON_PATH" >> validation_errors.txt
        echo "Validation Run At: $current_time" >> validation_errors.txt
        echo -e "$errors" >> validation_errors.txt
        echo "Validation errors have been saved to validation_errors.txt"
    else
        output="Validation error:$errors"
        echo -e "$output"
    fi
fi

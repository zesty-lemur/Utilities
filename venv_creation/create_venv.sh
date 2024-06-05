#!/bin/bash

ENV_NAME=".venv"
REQ_FILE="requirements.txt"
REBUILD=false
UPDATE_REQS=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --name) ENV_NAME="$2"; shift ;;
        --req-file) REQ_FILE="$2"; shift ;;
        --rebuild) REBUILD=true ;;
        --update-reqs) UPDATE_REQS=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

create_virtualenv() {
    local env_name="$1"
    python -m venv "$env_name"
    source "$env_name/bin/activate"
}

install_requirements() {
    local file="$1"
    if [[ -f "$file" ]]; then
        pip install -r "$file"
    else
        echo "No requirements file found, skipping installation."
    fi
}

rebuild_virtualenv() {
    local env_name="$1"
    if [[ -d "$env_name" ]]; then
        echo "Deactivating and rebuilding the virtual environment..."
        deactivate
        rm -rf "$env_name"
        create_virtualenv "$env_name"
        install_requirements "$REQ_FILE"
    fi
}

update_requirements() {
    local file="$1"
    local env_name="$2"
    local installed
    installed=$(pip freeze)
    
    if [[ -f "$file" ]]; then
        local requirements
        requirements=$(cat "$file")
        local diff
        diff=$(diff <(echo "$requirements") <(echo "$installed"))
        if [[ -n "$diff" ]]; then
            echo "The following packages differ:"
            echo "$diff"
            read -p "Do you want to update the requirements file? (y/n): " update
            if [[ "$update" == "y" ]]; then
                echo "# Updated on $(date)" >> "$file"
                echo "$installed" >> "$file"
            fi
        fi
    else
        echo "No requirements file found, creating a new one."
        echo "# Created on $(date)" > "$file"
        echo "$installed" >> "$file"
    fi
}

if [[ "$REBUILD" == true ]]; then
    read -p "Are you sure you want to rebuild the virtual environment? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        rebuild_virtualenv "$ENV_NAME"
    fi
else
    create_virtualenv "$ENV_NAME"
    install_requirements "$REQ_FILE"
fi

if [[ "$UPDATE_REQS" == true ]]; then
    update_requirements "$REQ_FILE" "$ENV_NAME"
fi

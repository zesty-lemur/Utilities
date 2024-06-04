# Utilities
A collection of command line utilities to solve annoying little problems.

## Table of Contents

|Utility|Description|Link|
|---|---|---|
|[JSON Validation](#json-validation)|A tool to compare a JSON file to a schema, available in three flavours: PowerShell, Bash, and Python|[View](/json_validation)|

## JSON Validation

A tool to compare a JSON file to a schema, available in three flavours:

- [PowerShell](/json_validation/validate_json.ps1) - Use `.\validate_json.ps1 -schemaPath <path_to_schema> -jsonPath <path_to_json> [--save-to-file]`
- [Bash](/json_validation/validate_json.sh) - Use `./validate_json.sh <path_to_schema> <path_to_json> [--save-to-file]`
- [Python](/json_validation/validate_json.py) - Use `python validate_json.py <path_to_schema> <path_to_json> [--save-to-file]`

Notes:

- Using the `--save-to-file` flag:
  - If enabled with the `--save-to-file` flag, any errors will be written to `validation_errors.txt` in the working directory; the file will also contain both the JSON file and schema paths, and the date / time of the validation check.
  - If `--save-to-file` is not enabled, any errors will be printed to the terminal.
  - If there are no errors, a validation message will be printed to the terminal, regardless of whether `--save-to-file` was used.
 
- Using the tool on Linux:
  - `jq` is required for the validation checks; the script will check if it's installed and, if not, will prompt the user to approve installation.
 
- Using the tool with Python:
  - The `jsonschema` library is required for the validation checks; the script will check if it's installed and, if not, will prompt the user to approve installation.
 

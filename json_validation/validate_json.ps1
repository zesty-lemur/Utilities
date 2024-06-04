# PowerShell Script: validate_json.ps1

param (
    [string]$schemaPath,
    [string]$jsonPath,
    [switch]$saveToFile
)

# Check if both arguments are provided
if (-not $schemaPath -or -not $jsonPath) {
    Write-Output "Usage: .\validate_json.ps1 -schemaPath <path_to_schema> -jsonPath <path_to_json> [--save-to-file]"
    exit 1
}

# Load the JSON schema
$schema = Get-Content -Raw -Path $schemaPath | ConvertFrom-Json

# Load the JSON data
$json = Get-Content -Raw -Path $jsonPath | ConvertFrom-Json

# Function to validate the JSON data against the schema
function Validate-Json {
    param (
        [Parameter(Mandatory=$true)]
        [PSObject]$data,

        [Parameter(Mandatory=$true)]
        [PSObject]$schema
    )

    $errors = @()

    function Validate-Object {
        param (
            [PSObject]$data,
            [PSObject]$schema,
            [string]$path = ""
        )

        foreach ($property in $schema.properties.PSObject.Properties) {
            $propName = $property.Name
            $propSchema = $property.Value

            if ($data.PSObject.Properties[$propName] -eq $null) {
                if ($schema.required -contains $propName) {
                    $errors += "$path/$propName is required"
                }
                continue
            }

            $propValue = $data.$propName

            switch ($propSchema.type) {
                "object" { Validate-Object -data $propValue -schema $propSchema -path "$path/$propName" }
                "array" { Validate-Array -data $propValue -schema $propSchema -path "$path/$propName" }
                "string" { if (-not ($propValue -is [string])) { $errors += "$path/$propName should be a string" } }
                "integer" { if (-not ($propValue -is [int])) { $errors += "$path/$propName should be an integer" } }
            }
        }
    }

    function Validate-Array {
        param (
            [PSObject]$data,
            [PSObject]$schema,
            [string]$path = ""
        )

        if ($data.Count -lt $schema.minItems) {
            $errors += "$path should have at least $($schema.minItems) items"
        }
        if ($data.Count -gt $schema.maxItems) {
            $errors += "$path should have at most $($schema.maxItems) items"
        }

        foreach ($item in $data) {
            Validate-Object -data $item -schema $schema.items -path $path
        }
    }

    Validate-Object -data $data -schema $schema

    return $errors
}

# Validate the JSON data
$validationErrors = Validate-Json -data $json -schema $schema

if ($validationErrors.Count -eq 0) {
    $output = "Validation successful: The JSON file is valid."
    Write-Output $output
} else {
    $output = "Validation error:`n" + ($validationErrors -join "`n")
    if ($saveToFile) {
        $current_time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $output = "Schema File: $schemaPath`nJSON File: $jsonPath`nValidation Run At: $current_time`n$output"
        $output | Out-File -FilePath "validation_errors.txt"
        Write-Output "Validation errors have been saved to validation_errors.txt"
    } else {
        Write-Output $output
    }
}

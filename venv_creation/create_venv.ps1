param(
    [string]$name = ".venv",
    [string]$reqFile = "requirements.txt",
    [switch]$rebuild,
    [switch]$updateReqs,
    [switch]$help
)

if ($help) {
    Write-Host "Usage: script.ps1 [--name ENV_NAME] [--req-file REQ_FILE] [--rebuild] [--update-reqs] [--help]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  --name         Name of the virtual environment (default: .venv)"
    Write-Host "  --req-file     Path to the requirements file (default: requirements.txt)"
    Write-Host "  --rebuild      Rebuild the virtual environment"
    Write-Host "  --update-reqs  Update the requirements file with missing packages"
    Write-Host "  --help         Display this help message"
    exit
}

function New-VirtualEnv {
    param(
        [string]$envName
    )
    python -m venv $envName
    & "$envName\Scripts\Activate"
}

function Install-Requirements {
    param(
        [string]$file
    )
    if (Test-Path $file) {
        pip install -r $file
    } else {
        Write-Host "No requirements file found, skipping installation."
    }
}

function Redo-VirtualEnv {
    param(
        [string]$envName
    )
    if (Test-Path $envName) {
        Write-Host "Deactivating and rebuilding the virtual environment..."
        & "$envName\Scripts\deactivate"
        Remove-Item -Recurse -Force $envName
        New-VirtualEnv $envName
        Install-Requirements $reqFile
    }
}

function Update-Requirements {
    param(
        [string]$file,
        [string]$envName
    )
    $installed = pip freeze
    if (Test-Path $file) {
        $requirements = Get-Content $file
        $diff = Compare-Object -ReferenceObject $requirements -DifferenceObject $installed
        if ($diff) {
            Write-Host "The following packages differ:"
            $diff | ForEach-Object { Write-Host $_.InputObject }
            $update = Read-Host "Do you want to update the requirements file? (y/n)"
            if ($update -eq 'y') {
                Add-Content $file "`n# Updated on $(Get-Date)"
                $installed | ForEach-Object { Add-Content $file $_ }
            }
        }
    } else {
        Write-Host "No requirements file found, creating a new one."
        Add-Content $file "`n# Created on $(Get-Date)"
        $installed | ForEach-Object { Add-Content $file $_ }
    }
}

if ($rebuild) {
    $confirm = Read-Host "Are you sure you want to rebuild the virtual environment? (y/n)"
    if ($confirm -eq 'y') {
        Redo-VirtualEnv $name
    }
} else {
    New-VirtualEnv $name
    Install-Requirements $reqFile
}

if ($updateReqs) {
    Update-Requirements $reqFile $name
}

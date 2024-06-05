param(
    [string]$name = ".venv",
    [string]$reqFile = "requirements.txt",
    [switch]$rebuild,
    [switch]$updateReqs
)

function Create-VirtualEnv {
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

function Rebuild-VirtualEnv {
    param(
        [string]$envName
    )
    if (Test-Path $envName) {
        Write-Host "Deactivating and rebuilding the virtual environment..."
        & "$envName\Scripts\deactivate"
        Remove-Item -Recurse -Force $envName
        Create-VirtualEnv $envName
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
        Rebuild-VirtualEnv $name
    }
} else {
    Create-VirtualEnv $name
    Install-Requirements $reqFile
}

if ($updateReqs) {
    Update-Requirements $reqFile $name
}

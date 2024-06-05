# Parse arguments manually
$scriptArgs = @{}
$scriptArgs.name = ".venv"
$scriptArgs.reqFile = "requirements.txt"
$scriptArgs.reset = $false
$scriptArgs.updateReqs = $false
$scriptArgs.help = $false

# Iterate over arguments
for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        "--name" {
            $i++
            $scriptArgs.name = $args[$i]
        }
        "--req-file" {
            $i++
            $scriptArgs.reqFile = $args[$i]
        }
        "--reset" {
            $scriptArgs.reset = $true
        }
        "--update-reqs" {
            $scriptArgs.updateReqs = $true
        }
        "--help" {
            $scriptArgs.help = $true
        }
    }
}

# Handling --help parameter
if ($scriptArgs.help) {
    Write-Host "Usage: script.ps1 [--name ENV_NAME] [--req-file REQ_FILE] [--reset] [--update-reqs] [--help]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  --name         Name of the virtual environment (default: .venv)"
    Write-Host "  --req-file     Path to the requirements file (default: requirements.txt)"
    Write-Host "  --reset        Reset the virtual environment"
    Write-Host "  --update-reqs  Update the requirements file with missing packages"
    Write-Host "  --help         Display this help message"
    exit
}

function Create-VirtualEnv {
    param(
        [string]$envName
    )
    Write-Host "Creating virtual environment..."
    python -m venv $envName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to create virtual environment" -ForegroundColor Red
        exit $LASTEXITCODE
    }
    Write-Host "Activating virtual environment..."
    . "$envName\Scripts\Activate.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to activate virtual environment" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

function Install-Requirements {
    param(
        [string]$file
    )
    if (Test-Path $file) {
        Write-Host "Installing requirements from $file..."
        pip install -r $file
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to install requirements" -ForegroundColor Red
            exit $LASTEXITCODE
        }
    } else {
        Write-Host "No requirements file found, skipping installation."
    }
}

function Reset-VirtualEnv {
    param(
        [string]$envName,
        [string]$reqFile
    )
    if (Test-Path $envName) {
        Write-Host "Deleting the virtual environment..."
        Remove-Item -Recurse -Force $envName
    }
    Create-VirtualEnv $envName
    Install-Requirements $reqFile
}

function Update-Requirements {
    param(
        [string]$file,
        [string]$envName
    )
    # Activate the virtual environment
    Write-Host "Activating virtual environment for update..."
    . "$envName\Scripts\Activate.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to activate virtual environment" -ForegroundColor Red
        exit $LASTEXITCODE
    }
    
    # Get the list of installed packages
    Write-Host "Retrieving installed packages..."
    $installed = pip list --format=freeze
    $installedModules = $installed -replace "==.*$"
    
    if (Test-Path $file) {
        $requirements = Get-Content $file
        $requirementsModules = $requirements -replace "==.*$"
        
        # Convert to arrays
        $installedModulesArray = $installedModules -split "`n"
        $requirementsModulesArray = $requirementsModules -split "`n"
        
        # Find packages in installed but not in requirements (missing in requirements)
        $missingInRequirements = $installedModulesArray | Where-Object { $_ -notin $requirementsModulesArray }
        
        if ($missingInRequirements.Count -gt 0) {
            Write-Host "The following packages are missing in the requirements file:"
            $missingInRequirements | ForEach-Object { Write-Host $_ }
            $update = Read-Host "Do you want to update the requirements file? (y/n)"
            if ($update -eq 'y') {
                Add-Content $file "`n# Updated on $(Get-Date)"
                $missingInRequirements | ForEach-Object { Add-Content $file $_ }
            }
        }
        
        # Find packages in requirements but not installed (missing in environment)
        $missingInEnvironment = $requirementsModulesArray | Where-Object { 
            $_ -notin $installedModulesArray -and $_ -ne "" -and $_ -notmatch "^#"
        }
        
        if ($missingInEnvironment.Count -gt 0) {
            Write-Host "The following packages are missing in the environment:"
            $missingInEnvironment | ForEach-Object { Write-Host $_ }
            $install = Read-Host "Do you want to install the missing packages? (y/n)"
            if ($install -eq 'y') {
                $missingInEnvironment | ForEach-Object { pip install $_ }
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "Failed to install some packages" -ForegroundColor Red
                    exit $LASTEXITCODE
                }
            }
        }
    } else {
        Write-Host "No requirements file found, creating a new one."
        Add-Content $file "`n# Created on $(Get-Date)"
        $installed | ForEach-Object { Add-Content $file $_ }
    }
}

# Handle --reset flag
if ($scriptArgs.reset) {
    $confirm = Read-Host "Are you sure you want to reset the virtual environment? (y/n)"
    if ($confirm -eq 'y') {
        Reset-VirtualEnv -envName $scriptArgs.name -reqFile $scriptArgs.reqFile
    }
} else {
    Create-VirtualEnv $scriptArgs.name
    Install-Requirements $scriptArgs.reqFile
}

# Handle --update-reqs flag
if ($scriptArgs.updateReqs) {
    Update-Requirements -file $scriptArgs.reqFile -envName $scriptArgs.name
}
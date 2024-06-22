$containers = Read-Host "Remove ALL containers? [y/N]"
$images = Read-Host "Remove ALL images? [y/N]"
$volumes = Read-Host "Remove ALL volumes? [y/N]"
$networks = Read-Host "Remove ALL networks? [y/N]"

$options = @()
$pairs = @(
    @($containers, 'containers'),
    @($images, 'images'),
    @($volumes, 'volumes'),
    @($networks, 'networks')
)

foreach ($pair in $pairs) {
    $option = $pair[0].ToLower()
    $statement = $pair[1]

    if ($option -eq 'y') {
        $options += $statement
    }
}

$optionsString = $options -join ', '

if ($optionsString) {
    $confirm = Read-Host "This will remove ALL $optionsString. Are you sure? [y/N]"
} else {
    Write-Host "Cancelled. Exiting."
    exit 1
}

if ($confirm.ToLower() -eq 'y') {
    foreach ($option in $options) {
        switch ($option) {
            'containers' {
                # Remove all containers
                Write-Host "Removing containers..."
                docker rm -f $(docker ps -aq)
            }
            'images' {
                # Remove all images
                Write-Host "Removing images..."
                docker rmi -f $(docker images -q)
            }
            'volumes' {
                # Remove all volumes
                Write-Host "Removing volumes..."
                docker volume rm $(docker volume ls -q)
            }
            'networks' {
                # Remove all networks
                Write-Host "Removing networks..."
                docker network rm $(docker network ls -q)
            }
        }
    }
    # Confirm completion
    Write-Host "Completed removal of $optionsString. Exiting."
} else {
    Write-Host "Cancelled. Exiting."
    exit 1
}
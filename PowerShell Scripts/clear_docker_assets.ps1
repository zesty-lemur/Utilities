$confirm = Read-Host "This will remove ALL Docker assets. Are you sure? [y/N]"

if ($confirm.ToLower() -eq 'y') {
    # Remove all containers
    Write-Host "Removing containers..."
    docker rm -f $(docker ps -aq)
    # Remove all images
    Write-Host "Removing images..."
    docker rmi -f $(docker images -q)
    # Remove all volumes
    Write-Host "Removing volumes..."
    docker volume rm $(docker volume ls -q)
    # Remove all networks
    Write-Host "Removing networks..."
    docker network rm $(docker network ls -q)
    # Confirm completion
    Write-Host "Complete. Exiting."
}
else {
    Write-Host "Cancelled. Exiting."
    exit 1
}
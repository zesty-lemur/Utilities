$rawPath = Get-Clipboard

$rawPath = $rawPath.Replace('"','')

$targetPath = Split-Path -Path $rawPath

code $targetPath
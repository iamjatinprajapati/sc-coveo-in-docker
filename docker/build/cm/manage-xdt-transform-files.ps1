$envName = $env:SC_ENVIRONMENT

Write-Host "Provided environment name: " $envName

Write-Host "Removing unwanted .xdt files..."
# Remove .xdt files for other environments than the provided one.
Get-ChildItem -Path $env:XDT_FILES_PATH -Filter "web.config*.xdt" -Exclude "web.config-$envName.xdt" -Recurse | ForEach-Object {
    Write-Host "Removing $($_.FullName)..."
    Remove-Item $_.FullName
}
Get-ChildItem -Path $env:XDT_FILES_PATH -Filter "ConnectionStrings.config*.xdt" -Exclude "ConnectionStrings.config-$envName.xdt" -Recurse | ForEach-Object {
    Write-Host "Removing $($_.FullName)..."
    Remove-Item $_.FullName
}
# Remove-Item $env:XDT_FILES_PATH -Filter "web.config.*.xdt" -Exclude "web.config-$envName.xdt" -Recurse
# Remove-Item $env:XDT_FILES_PATH -Filter "ConnectionStrings.*.xdt" -Exclude "ConnectionStrings.config-$envName.xdt" -Recurse

Write-Host "Renaming the environment specific .xdt files..."
Get-ChildItem $env:XDT_FILES_PATH -Filter "web.config-$env:SC_ENVIRONMENT.xdt" -Recurse | Rename-Item -NewName { $_.Name -replace "-$envName.xdt", ".xdt" }
Get-ChildItem $env:XDT_FILES_PATH -Filter "ConnectionStrings.config-$env:SC_ENVIRONMENT.xdt" -Recurse | Rename-Item -NewName { $_.Name -replace "-$envName.xdt", ".xdt" }

$xdtFiles = Get-ChildItem $env:XDT_FILES_PATH -Filter "*.xdt" -Recurse

if($xdtFiles.Length -gt 0){
    Write-Host "Following .xdt files found..."
    Get-ChildItem $env:XDT_FILES_PATH -Filter "*.xdt" -Recurse | ForEach-Object {
        Write-Host $_.FullName
    }
    Get-ChildItem "$env:XDT_FILES_PATH\*\website" -Recurse | ForEach-Object { & C:\tools\scripts\Invoke-XdtTransform.ps1 -Path .\ -XdtPath $_.FullName }
}
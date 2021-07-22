Import-Module -Name (Join-Path $PSScriptRoot "docker\tools\cli") -Force

if (!(Test-IsEnvInitialized -FilePath ".\docker\.env")){
    Write-Host "Creating .env file from .env.sample!!!" -ForegroundColor Green
    Copy-Item ".\docker\.env.sample" -Destination ".\docker\.env"
    Write-Host "Successfully created .env file!!!" -ForegroundColor Green
}

if (!(Test-Path ".\Directory.build.props")){
    Write-Host "Creating Directory.build.props file!!!" -ForegroundColor Green
    Copy-Item ".\Directory.build.props.sample" -Destination ".\Directory.build.props"
    Write-Host "Successfully created Directory.build.props file!!!" -ForegroundColor Green
}
if (!(Test-Path ".\Directory.build.targets")){
    Write-Host "Creating Directory.build.targets file!!!" -ForegroundColor Green
    Copy-Item ".\Directory.build.targets.sample" -Destination ".\Directory.build.targets"
    Write-Host "Successfully created Directory.build.targets file!!!" -ForegroundColor Green
}

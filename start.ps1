#Requires -RunAsAdministrator

Import-Module -Name (Join-Path $PSScriptRoot "docker\tools\cli") -Force

Stop-Docker -TakeDown

Clear-Host

$isDockerRunning = $false
try{
    $result = Get-Process 'com.docker.proxy'
    Write-Host $result.Name
    $isDockerRunning = $result.Name -eq "com.docker.proxy"
}
catch{
    
}

if(!($isDockerRunning)){
    Write-Host "Docker is not started. Please start the docker and run this script again." -ForegroundColor Red
    exit 0
}

# if (!(Test-IsEnvInitialized -FilePath ".\docker\.env")){
#     Write-Host ".env file is not found. Please use init.ps1 to create one"
#     exit 0
# }


if (Test-IsEnvInitialized -FilePath ".\docker\.env" ) {
    Write-Host "Docker environment is present, starting docker.." -ForegroundColor Green

    if (!(Test-Path ".\docker\traefik\certs\cert.pem")) {
        Write-Host "TLS certificate for Traefik not found, generating and adding hosts file entries" -ForegroundColor Green
        Install-SitecoreDockerTools
        $hostDomain = Get-EnvValueByKey "HOST_DOMAIN"
        if ($hostDomain -eq "") {
            throw "Required variable 'HOST_DOMAIN' not set in .env file."
        }
        Initialize-HostNames $hostDomain
        Start-Docker -Url "$(Get-EnvValueByKey "CM_HOST")/sitecore" -Build
        exit 0
    }
    Start-Docker -Url "$(Get-EnvValueByKey "CM_HOST")/sitecore" -Build
    exit 0
}

# if ((Test-Path ".\*.sln")) {
#     Write-Host "A solution file already exist but no initialized docker environmnent was found, and hence initializing the docker environment."
#     if (Test-Path (Join-Path $PSScriptRoot "docker")) {
#         Remove-Item (Join-Path $PSScriptRoot "docker") -Force -Recurse
#     }
# }

if(!(Test-Path ".\docker\license\license.xml")){
    Write-Host "Please put the license.xml in to the .\docker\license folder" -ForegroundColor Red
    exit 0
}

$solutionName = "sc-docker-coveo"

#$esc = [char]27


$dockerPreset = "sitecore-xp0-sxa"

Write-Host "$($dockerPreset) selected.." -ForegroundColor Magenta

#Install-DockerStarterKit -Name $dockerPreset -IncludeSolutionFiles $true

#Rename-SolutionFile $solutionName
#Install-SitecoreDockerTools

$hostDomain = "$($solutionName.ToLower()).localhost"
$hostDomain = Read-ValueFromHost -Question "Domain Hostname (press enter for $($hostDomain))" -DefaultValue $hostDomain -Required
Initialize-HostNames $hostDomain

# do {
#     $licenseFolderPath = Read-ValueFromHost -Question "Path to a folder that contains your Sitecore license.xml file `n- must contain a file named license.xml file (press enter for .\License\)" -DefaultValue ".\License\" -Required
# } while (!(Test-Path (Join-Path $licenseFolderPath "license.xml")))

# Copy-Item (Join-Path $licenseFolderPath "license.xml") ".\docker\license\"
# Write-Host "Copied license.xml to .\docker\license\" -ForegroundColor Magenta

Push-Location ".\docker"
Set-EnvFileVariable "COMPOSE_PROJECT_NAME" -Value $solutionName.ToLower() 
Set-EnvFileVariable "HOST_LICENSE_FOLDER" -Value ".\license"
Set-EnvFileVariable "HOST_DOMAIN"  -Value $hostDomain
Set-EnvFileVariable "CM_HOST" -Value "cm.$($hostDomain)"
Set-EnvFileVariable "CD_HOST" -Value "cd.$($hostDomain)"
Set-EnvFileVariable "ID_HOST" -Value "id.$($hostDomain)"
#Set-EnvFileVariable "RENDERING_HOST" -Value "www.$($hostDomain)"

Set-EnvFileVariable "REPORTING_API_KEY" -Value (Get-SitecoreRandomString 128 -DisallowSpecial)
Set-EnvFileVariable "TELERIK_ENCRYPTION_KEY" -Value (Get-SitecoreRandomString 128)
Set-EnvFileVariable "MEDIA_REQUEST_PROTECTION_SHARED_SECRET" -Value (Get-SitecoreRandomString 64 -DisallowSpecial)
Set-EnvFileVariable "SITECORE_IDSECRET" -Value (Get-SitecoreRandomString 64 -DisallowSpecial)
$idCertPassword = Get-SitecoreRandomString 8 -DisallowSpecial
Set-EnvFileVariable "SITECORE_ID_CERTIFICATE" -Value (Get-SitecoreCertificateAsBase64String -DnsName "localhost" -Password (ConvertTo-SecureString -String $idCertPassword -Force -AsPlainText))
Set-EnvFileVariable "SITECORE_ID_CERTIFICATE_PASSWORD" -Value $idCertPassword
Set-EnvFileVariable "SQL_SA_PASSWORD" -Value (Get-SitecoreRandomString 19 -DisallowSpecial -EnforceComplexity)
Pop-Location
# Set-EnvFileVariable "SITECORE_VERSION" -Value "10.1-ltsc2019"
# Set-EnvFileVariable "SITECORE_ADMIN_PASSWORD" -Value "b"
# Set-EnvFileVariable "SPE_VERSION" -Value "6.2-1809"
# Set-EnvFileVariable "ISOLATION" -Value "default"

# if (Confirm -Question "Would you like to adjust container memory limits?") {
#     Set-EnvFileVariable "MEM_LIMIT_SQL" -Value (Read-ValueFromHost -Question "SQL Server memory limit (default: 4GB)" -DefaultValue "4GB" -Required)
#     Set-EnvFileVariable "MEM_LIMIT_SOLR" -Value (Read-ValueFromHost -Question "Solr memory limit (default: 2GB)" -DefaultValue "2GB" -Required)
#     Set-EnvFileVariable "MEM_LIMIT_CM" -Value (Read-ValueFromHost -Question "CM Server memory limit (default: 4GB)" -DefaultValue "4GB" -Required)
# }

Start-Docker -Url "cm.$($hostDomain)/sitecore" -Build

Pop-Location
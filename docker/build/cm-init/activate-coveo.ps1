$cmUrl = $env:sc_cm
$RequestTimeout = 300

Write-Host "API key: " $env:COVEO_API_KEY
Write-Host "Organization id: " $env:COVEO_ORGANIZATION_ID
Write-Host "Search API key: " $env:COVEO_SEARCH_API_KEY
Write-Host "Sitecore username: " $env:COVEO_SITECORE_USERNAME
Write-Host "Sitecore user password: " $env:COVEO_SITECORE_USER_PASSWORD
Write-Host "Farm: " $env:COVEO_FARM_NAME
Write-Host "Script user name: " $env:COVEO_SCRIPT_SITECORE_USERNAME
Write-Host "Script password: " $env:COVEO_SCRIPT_SITECOREPASSWORD

function InvokeWebRequest {
    param (
        [string]$Endpoint,
        [int]$RequestTimeout
    )

    try {
        $response = Invoke-WebRequest -Uri $Endpoint -UseBasicParsing -TimeoutSec $RequestTimeout
    }
    catch {
        $response = $_.Exception.Response
    }
    finally {
        Write-Information -MessageData "$Endpoint - $($response.StatusCode)" -InformationAction:Continue

        if ($response.StatusCode -eq 200) {
            $returnCode = 0
        } else {
            $returnCode = 1
        }
    }

    return $returnCode
}

function Configure-CoveoForSitecorePackage([Parameter(Mandatory=$true)]
                                           [string] $SitecoreInstanceUrl,
                                           [string] $CoveoForSitecoreApiVersion = "v1",
                                           [string] $OrganizationId,
                                           [string] $ConfigApiKey,
                                           [string] $SearchApiKey,
                                           [boolean] $DisableSourceCreation = $false,
                                           [string] $CoveoSitecoreUsername,
                                           [string] $CoveoSitecorePassword,
                                           [string] $DocumentOptionsBodyIndexing = "Rich",
                                           [boolean] $DocumentOptionsIndexPermissions = $true,
                                           [string] $FarmName,
                                           [boolean] $BypassCoveoForSitecoreProxy = $false,
                                           [Parameter(Mandatory=$true)]
                                           [string] $ScriptSitecoreUsername,
                                           [Parameter(Mandatory=$true)]
                                           [string] $ScriptSitecorePassword)
{
    $ConfigureCoveoForSitecoreUrl = $SitecoreInstanceUrl + "/coveo/api/config/" + $CoveoForSitecoreApiVersion + "/configure"
    $Body = @{ }
    if (![string]::IsNullOrEmpty($OrganizationId)) {
        $Body.Organization = @{
            "OrganizationId" = $OrganizationId
            "ApiKey" = $ConfigApiKey
            "SearchApiKey" = $SearchApiKey
            "DisableSourceCreation" = $DisableSourceCreation
        }
        $Body.SitecoreCredentials = @{
            "Username" = $CoveoSitecoreUsername
            "Password" = $CoveoSitecorePassword
        }
        $Body.DocumentOptions = @{
            "BodyIndexing" = $DocumentOptionsBodyIndexing
            "IndexPermissions" = $DocumentOptionsIndexPermissions
        }
        $Body.Proxy = @{
            "BypassCoveoForSitecoreProxy" = $BypassCoveoForSitecoreProxy
        }
    }
    if (![string]::IsNullOrEmpty($FarmName)) {
        $Body.Farm = @{
            "Name" = $FarmName
        }
    }
    $BodyJson = $Body | ConvertTo-Json
    $m_Headers = @{
        "x-scUsername" = $ScriptSitecoreUsername
        "x-scPassword" = $ScriptSitecorePassword
    }
    Write-Host "Configuring the Coveo for Sitecore package... "
    Try {
        Invoke-RestMethod -Uri $ConfigureCoveoForSitecoreUrl -Method PUT -Body $BodyJson -Headers $m_Headers -ContentType "application/json"
        Write-Host "The Coveo for Sitecore package is now configured."
    }
    Catch {
        Write-Host "There was an error during your Coveo for Sitecore package configuration:"
        Write-Host $PSItem
    }
}

function Activate-CoveoForSitecorePackage([Parameter(Mandatory=$true)]
                                          [string] $SitecoreInstanceUrl,
                                          [string] $CoveoForSitecoreApiVersion = "v1",
                                          [Parameter(Mandatory=$true)]
                                          [string] $ScriptSitecoreUsername,
                                          [Parameter(Mandatory=$true)]
                                          [string] $ScriptSitecorePassword)
{
    $ActivateCoveoForSitecoreUrl = $SitecoreInstanceUrl + "/coveo/api/config/" + $CoveoForSitecoreApiVersion + "/activate"
    $m_Headers = @{
        "x-scUsername" = $ScriptSitecoreUsername
        "x-scPassword" = $ScriptSitecorePassword
    }
    Write-Host "Activating the Coveo for Sitecore package... "
    Try {
        Invoke-RestMethod -Uri $ActivateCoveoForSitecoreUrl -Method POST -Headers $m_Headers -ContentType "application/json"
        Write-Host "The Coveo for Sitecore package is now activated."
    }
    Catch {
        Write-Host "There was an error during your Coveo for Sitecore package activation:"
        Write-Host $PSItem
    }
}

$result = 1

while($result -eq 1){
    $result = InvokeWebRequest -Endpoint $cmUrl -RequestTimeout $RequestTimeout
    if($result -eq 0){
        Write-Host "CM is up and available..." -ForegroundColor Green
        Write-Host "Configuring Coveo for Sitecore..." -ForegroundColor Green
        Configure-CoveoForSitecorePackage -SitecoreInstanceUrl $cmUrl -OrganizationId $env:COVEO_ORGANIZATION_ID -ConfigApiKey $env:COVEO_API_KEY -SearchApiKey $env:COVEO_SEARCH_API_KEY -CoveoSitecoreUsername $env:COVEO_SITECORE_USERNAME -CoveoSitecorePassword $env:COVEO_SITECORE_USER_PASSWORD -ScriptSitecoreUsername $env:COVEO_SCRIPT_SITECORE_USERNAME -ScriptSitecorePassword $env:COVEO_SCRIPT_SITECOREPASSWORD
        Activate-CoveoForSitecorePackage -SitecoreInstanceUrl $cmUrl -ScriptSitecoreUsername $env:COVEO_SCRIPT_SITECORE_USERNAME -ScriptSitecorePassword $env:COVEO_SCRIPT_SITECOREPASSWORD
        return 0
    }
    Write-Host "Waiting for CM to come up..."
}
param(
    #[Parameter(Mandatory)]
    [string] $configPath
)

$coveoPrefix = "COVEO_"

Write-Host "Path to search coveo files: $configPath"

$coveoFiles = Get-ChildItem -Path $configPath -Include "Coveo*.config" -Recurse

ForEach($coveoFile in $coveoFiles){
    Write-Host "Reading content for: " $coveoFile
    Get-ChildItem env:* | ForEach-Object {
        if($_.Key.StartsWith($coveoPrefix)){
            $doc = Get-Content -Path $coveoFile -Raw
            if($doc.Contains($_.Key)){
                ((Get-Content -Path $coveoFile -Raw) -replace $_.Key,$_.Value) | Set-Content -Path $coveoFile
                Write-Host "Replaced " $_.Key "with" $_.value "..."
            }
        }
    }
}
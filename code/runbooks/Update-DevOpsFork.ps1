Param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Location,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $SubscriptionId,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataLandingZoneName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $SubnetId,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $StorageAccountName,

    [Parameter(Mandatory=$false)]
    [Switch]
    $StorageAccountFileSystemName,

    [Parameter(Mandatory=$false)]
    [Switch]
    $AzureResourceManagerConnectionName
)

function Clone-DevOpsRepostory {
    [CmdletBinding()]
    param (
        
    )
    # Clone Repository
    Write-Host "Cloning Repository"
    git clone ""
}



$configs = Get-Content -Path "config.json" -Raw | Out-String | ConvertFrom-Json
$Location = "WestEurope"
$SubscriptionId = "xxxxxx.xxxxxxxxxxxxxxxxx.xxxxxxxxxxx"
$DataLandingZoneName = "MyLandingZone"
$SubnetId = ""
$StorageAccountName = ""
$StorageAccountFileSystemName = ""
$AzureResourceManagerConnectionName = ""


function SetValue($Object, $Key, $Value) {
    $p1, $p2 = $Key.Split(".")
    if ($p2) { 
        SetValue -object $Object.$p1 -key $p2 -Value $Value 
    }
    else { 
        $Object.$p1 = $Value
    }
}


Write-Host "Loading YAML Deployment File"
$parameterFile = Get-Content -Path ".ado/workflows/dataDomainDeployment.yml" -Raw | Out-String | ConvertFrom-Yaml -Ordered
Write-Host $parameterFile.variables.AZURE_RESOURCE_MANAGER_CONNECTION_NAME

$key = "variables.AZURE_RESOURCE_MANAGER_CONNECTION_NAME"
$value = "testtest"
SetValue -Object $parameterFile -Key $key -Value $value

Write-Host $parameterFile.variables.AZURE_RESOURCE_MANAGER_CONNECTION_NAME


foreach ($config in $configs) {
    # Get Replacement Key-Value Pairs
    Write-Host "Getting Replacement Key-Value Pairs"
    $parameterReplacements = @{}
    $config.parameters.psobject.properties | ForEach-Object { $parameterReplacements[$_.Name] = $_.Value }
    
    if ($config.fileType.ToLower() -eq "json") {
        # Load ARM Parameter File
        Write-Host "Loading ARM Parameter File"
        $parameterFile = Get-Content -Path $config.filePath -Raw | Out-String | ConvertFrom-Json
    
        # Replace Parameter Values
        Write-Host "Replacing Parameter Values"
        foreach ( $parameterReplacementPair in $parameterReplacements.GetEnumerator() ) {
            $key = $parameterReplacementPair.Key
            $value = $parameterReplacementPair.Value
            $value = $ExecutionContext.InvokeCommand.ExpandString($value)

            # Replace Parameter
            Write-Host "Replacing Parameter '${key}' with Value '${value}'"
            SetValue -Object $parameterFile -Key $key -Value $value
        }

        # Set Content of Parameter File
        Write-Host "Setting Content of Parameter File"
        $parameterFile | ConvertTo-Json | Set-Content -Path $config.filePath
    }
    elseif (($config.fileType.ToLower() -eq "yaml") -or ($config.fileType.ToLower() -eq "yml")) {
        # Load YAML Deployment File
        Write-Host "Loading YAML Deployment File"
        $parameterFile = Get-Content -Path $config.filePath -Raw | Out-String | ConvertFrom-Yaml -Ordered

        # Replace Variables
        Write-Host "Replacing Variables"
        foreach ( $parameterReplacementPair in $parameterReplacements.GetEnumerator() ) {
            $key = $parameterReplacementPair.Key
            $value = $parameterReplacementPair.Value
            $value = $ExecutionContext.InvokeCommand.ExpandString($value)

            # Replace Parameter
            Write-Host "Replacing Parameter '${key}' with Value '${value}'"
            SetValue -Object $parameterFile -Key $key -Value $value
        }

        # Set Content of Parameter File
        Write-Host "Setting Content of Parameter File"
        $parameterFile | ConvertTo-Yaml | Set-Content -Path $config.filePath
    }
    else {
        Write-Error "File Type not Supported"
        throw "File Type not Supported"
    }

    
}
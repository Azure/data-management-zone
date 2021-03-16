[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ConfigurationFilePath,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataLandingZoneSubscriptionId,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataLandingZoneName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Location,

    [Parameter(Mandatory=$false)]
    [string]
    $AzureResourceManagerConnectionName
)

function SetValue($Object, $Key, $Value) {
    $p1, $p2 = $Key.Split(".")
    if ($p2) { 
        SetValue -object $Object.$p1 -key $p2 -Value $Value 
    }
    else { 
        $Object.$p1 = $Value
    }
}


function Remove-SpecialCharsAndWhitespaces($InputString) {
    $SpecialChars = '[#?!`"#$%&*+,-./:;<=>?@^_``|~\{\[\(\)\]\}]'
    $Replacement  = ''
    return ($InputString -replace $SpecialChars,$Replacement) -replace "\s", ""
}


# Replace Special Characters
Write-Host "Replacing Special Characters"
$DataLandingZoneName = Remove-SpecialCharsAndWhitespaces -InputString $DataLandingZoneName

# Reduce Length of DataLandingZoneName
Write-Host "Reduce Length of DataLandingZoneName to Max 11 Characters"
$DataLandingZoneName = -join $DataLandingZoneName[0..11]

# Convert DataLandingZoneName to lowercase
Write-Host "Converting DataLandingZoneName to lowercase"
$DataLandingZoneName = $DataLandingZoneName.ToLower()

# Loading Configuration File for Parameter Updates
Write-Host "Loading Configuration File for Parameter Updates"
$configs = Get-Content -Path $ConfigurationFilePath -Raw | Out-String | ConvertFrom-Json

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
        $parameterFile | ConvertTo-Json -Depth 100 | Set-Content -Path $config.filePath
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

# Set output
Write-Output "Setting output"
Write-Output "::set-output name=landingZoneName::${DataLandingZoneName}"

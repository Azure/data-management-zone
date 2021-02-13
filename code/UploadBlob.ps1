[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $StorageAccountName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $StorageAccountContainerName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $File,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Blob
)

# Get Storage Account Context
Write-Host "Getting Storage Account Context"
$storageAccount = Get-AzStorageAccount `
    -ResourceGroupName "${ResourceGroupName}" `
    -Name "${StorageAccountName}"
$ctx = $storageAccount.Context

# Upload File to Storage Account
Write-Host "Uploading Data to Storage Account"
Set-AzStorageBlobContent `
    -Context $ctx `
    -Container "${StorageAccountContainerName}" `
    -File "${File}" `
    -Blob "${Blob}" `
    -Force

# Successfully Uploaded Blob
Write-Host "Successfully Uploaded Blob"
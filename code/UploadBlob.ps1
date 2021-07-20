# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

# Define script arguments
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
Write-Output "Getting Storage Account Context"
$storageAccount = Get-AzStorageAccount `
    -ResourceGroupName "${ResourceGroupName}" `
    -Name "${StorageAccountName}"
$ctx = $storageAccount.Context

# Upload File to Storage Account
Write-Output "Uploading Data to Storage Account"
Set-AzStorageBlobContent `
    -Context $ctx `
    -Container "${StorageAccountContainerName}" `
    -File "${File}" `
    -Blob "${Blob}" `
    -Force

# Successfully Uploaded Blob
Write-Output "Successfully Uploaded Blob"
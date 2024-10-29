<#
.SYNOPSIS
    Sets up a Purview account with specified parameters.

.DESCRIPTION
    This script installs the required Az.Purview module, defines necessary parameters, and optionally sets the specified Purview account as the default account in the tenant.

.PARAMETER PurviewId
    The resource ID of the Purview account.

.PARAMETER PurviewRootCollectionAdmins
    An array of root collection administrators for the Purview account.

.PARAMETER SetPurviewAccountAsDefault
    A switch to set the specified Purview account as the default account in the tenant.

.EXAMPLE
    .\SetupPurview.ps1 -PurviewId "/subscriptions/xxxx/resourceGroups/xxxx/providers/Microsoft.Purview/accounts/xxxx" -SetPurviewAccountAsDefault

.NOTES
    Copyright (c) Microsoft Corporation.
    Licensed under the MIT license.
#>


# Define script arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $PurviewId,

    [Parameter(Mandatory = $false)]
    [string[]]
    $PurviewRootCollectionAdmins = @(),

    [Parameter(Mandatory=$false)]
    [Switch]
    $SetPurviewAccountAsDefault
)

# Install Required Module
Write-Output "Installing Required Module"
Set-PSRepository `
    -Name PSGallery `
    -InstallationPolicy Trusted
Install-Module `
    -Name Az.Purview `
    -Repository PSGallery `
    -Force

# Define Parameters
Write-Output "Defining Parameters"
$tenantId = (Get-AzContext).Tenant.Id
$purviewSubscriptionId = $PurviewId.Split("/")[2]
$purviewResourceGroupName = $PurviewId.Split("/")[4]
$purviewAccountName = $PurviewId.Split("/")[8]

if ($SetPurviewAccountAsDefault) {
    # Set Purview Account as Default in Tenant
    Write-Output "Setting Purview Account as Default in Tenant"
    Set-AzPurviewDefaultAccount `
        -ScopeTenantId $tenantId `
        -ScopeType "Tenant" `
        -Scope $tenantId `
        -SubscriptionId $purviewSubscriptionId `
        -ResourceGroupName $purviewResourceGroupName `
        -AccountName $purviewAccountName
} else {
    # NOT Set Purview Account as Default in Tenant
    Write-Output "NOT Setting Purview Account as Default in Tenant"
}

foreach ($purviewRootCollectionAdmin in $PurviewRootCollectionAdmins) {
    # Set Purview Root Collection Admin
    Write-Output "Setting Purview Root Collection Admin '${purviewRootCollectionAdmin}'"
    Add-AzPurviewAccountRootCollectionAdmin `
        -SubscriptionId $purviewSubscriptionId `
        -ResourceGroupName $purviewResourceGroupName `
        -AccountName $purviewAccountName `
        -ObjectId $purviewRootCollectionAdmin
}

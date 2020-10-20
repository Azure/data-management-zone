# This sample helps automate the installation and configuration of the On-premises data gateway using available PowerShell cmdlets.
# This script helps with silent install of new gateway cluster with one gateway member only. The script also allows addition gateway 
# admins. For information on each PowerShell script visit the help page for individual PowerSHell cmdlets. Before begining to install
# and register a gateway, for connecting to the gateway service, you would need to use the # Connect-DataGatewayServiceAccount. More
# information documented in the help page of that cmdlet.

Param(
    # Name of the Power BI Gateway
    [Parameter(Mandatory = $true)]
    [String]
    $GatewayName,

    # Application Id for login
    [Parameter()]
    [String]
    $TenantId,

    # Application Id for login
    [Parameter()]
    [String]
    $ApplicationId,

    # Application Id for login
    [Parameter()]
    [String]
    $ClientSecret,

    # Recovery Key of the Power BI Gateway
    [Parameter(Mandatory = $true)]
    [String]
    $RecoveryKey,

    # Region of the Power BI Gateway
    [Parameter(Mandatory = $true)]
    [String]
    $RegionKey,

    [Parameter()]
    [Guid]
    $AdditionalGatewayAdminGroupId
)
$ErrorActionPreference = "stop"

# Print pwsh version
$psVersion = (Get-Host).Version
Write-Host $psVersion

# Convert input parameters
$clientSecretSecureString = $ClientSecret | ConvertTo-SecureString -AsPlainText -Force
$recoveryKeySecureString = $RecoveryKey | ConvertTo-SecureString -AsPlainText -Force

# Install DataGateway module
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
Install-Module -Name DataGateway

# Connect to the Data Gateway service
$connectDataGatewayServiceAccountArguments = @{
    ApplicationId = $ApplicationId;
    ClientSecret  = $clientSecretSecureString;
    Environment   = "Public";
    Tenant        = $TenantId;
}
Connect-DataGatewayServiceAccount @connectDataGatewayServiceAccountArguments

# Thrown an error if not logged in
Get-DataGatewayAccessToken | Out-Null

# Run the gateway installer on the local computer
Install-DataGateway -AcceptConditions

# Create a gateway cluster and save the cluster ID
$addDataGatewayClusterArguments = @{
    RecoveryKey              = $recoveryKeySecureString;
    GatewayName              = $GatewayName;
    RegionKey                = "northeurope";
    OverwriteExistingGateway = $true;
}
$newGatewayClusterId = (Add-DataGatewayCluster @addDataGatewayClusterArguments).GatewayObjectId

# Optionally add admin to new gateway
if ($null -ne $AdminPrincipalObjectIdForNewGateway) {
    $addDataGatewayClusterUserArguments = @{
        GatewayClusterId       = $newGatewayClusterId;
        PrincipalObjectId      = $AdditionalGatewayAdminGroupId;
        Role                   = "Admin";
        AllowedDataSourceTypes = $null;
    }
    Add-DataGatewayClusterUser @addDataGatewayClusterUserArguments
}

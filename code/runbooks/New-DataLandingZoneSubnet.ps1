Param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $VirtualNetworkId,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $NetworkSecurityGroupId,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $RouteTableId,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $SubnetName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $SubnetCidrRange,

    [Parameter(Mandatory=$false)]
    [Switch]
    $PrivateLink
)

# Get Names for Setup
Write-Host "Getting Names for Setup"
$virtualNetworkObject = $VirtualNetworkId -split "/"
$subscriptionId = $virtualNetworkObject[2]
$resourceGroupName = $virtualNetworkObject[4]
$virtualNetworkName = $virtualNetworkObject[8]

$networkSecurityGroupIdObject = $NetworkSecurityGroupId -split "/"
$networkSecurityGroupName = $networkSecurityGroupIdObject[8]

$routeTableIdObject = $RouteTableId -split "/"
$routeTableName = $routeTableIdObject[8]

# Get automation connection
Write-Host "Getting Automation Connection"
$connection = Get-AutomationConnection `
    -Name "AzureRunAsConnection"

# Get Az Connection
Write-Host "Getting Az Connection"
Connect-AzAccount `
    -Tenant $connection.TenantID `
    -ApplicationId $connection.ApplicationID `
    -CertificateThumbprint $connection.CertificateThumbprint

# Set Az Context
Write-Host "Setting Az Context"
Set-AzContext `
    -Subscription $subscriptionId

# Get Virtual Network
Write-Host "Getting Virtual Network"
$virtualNetwork = Get-AzVirtualNetwork `
    -Name $virtualNetworkName `
    -ResourceGroupName $resourceGroupName `

# Get Route Table
Write-Host "Getting Route Table"
$routeTable = Get-AzRouteTable `
    -Name $routeTableName `
    -ResourceGroupName $resourceGroupName `

# Get Network Security Group
Write-Host "Getting Network Security Group"
$networkSecurityGroup = Get-AzVirtualNetwork `
    -Name $networkSecurityGroupName `
    -ResourceGroupName $resourceGroupName `

# Add Subnet to VirtualNetwork
Write-Host "Adding Subnet to VirtualNetwork"
if ($PrivateLink) {
    Add-AzVirtualNetworkSubnetConfig `
        -Name $SubnetName `
        -VirtualNetwork $virtualNetwork `
        -AddressPrefix $SubnetCidrRange `
        -NetworkSecurityGroup $networkSecurityGroup `
        -RouteTable $routeTable `
        -PrivateEndpointNetworkPoliciesFlag "Disabled" `
        -PrivateLinkServiceNetworkPoliciesFlag "Disabled"
    $virtualNetwork | Set-AzVirtualNetwork
}
else {
    Add-AzVirtualNetworkSubnetConfig `
        -Name $SubnetName `
        -VirtualNetwork $virtualNetwork `
        -AddressPrefix $SubnetCidrRange `
        -NetworkSecurityGroup $networkSecurityGroup `
        -RouteTable $routeTable `
        -PrivateEndpointNetworkPoliciesFlag "Enabled" `
        -PrivateLinkServiceNetworkPoliciesFlag "Enabled"
    $virtualNetwork | Set-AzVirtualNetwork
}

# Create Output
Write-Host "Creating Output"
$output = @{
    "SubnetId" = "${VirtualNetworkId}/subnets/${SubnetName}"
}
Write-Output ( $output | ConvertTo-Json)

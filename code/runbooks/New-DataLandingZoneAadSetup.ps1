Param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $EnterpriseScalePrefix,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataLandingZoneName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataLandingZoneType,
    
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataLandingZoneSubscriptionId,
    
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataLandingZoneLocation,
    
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $DataLandingZoneSubnetIds,
    
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataLandingZoneOwnerObjectId,
    
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataLandingZoneCostCode
)

# Get automation connection
Write-Host "Getting Automation Connection"
$connection = Get-AutomationConnection `
    -Name "AzureRunAsConnection"

# Connect to Azure AD
Write-Host "Connecting to Azure AD"
Connect-AzureAD `
    -Tenant $connection.TenantID `
    -ApplicationId $connection.ApplicationID `
    -CertificateThumbprint $connection.CertificateThumbprint

# Create Azure AD Security Group
Write-Host "Creating Azure AD Security Group"
$securityGroup = New-AzureADGroup `
    -DisplayName "dd-${DataLandingZoneName}" `
    -Description "Security Group of ${DataLandingZoneType} ${DataLandingZoneName}" `
    -MailEnabled $false `
    -MailNickName "NotSet" `
    -SecurityEnabled $true

# Create Application
$application = New-AzureADApplication `
    -DisplayName "${DataLandingZoneName}-Application" `
    -IdentifierUris "https://${DataLandingZoneName}.${EnterpriseScalePrefix}.com"

# Create Service Principal
Write-Host "Creating Service Principle"
$servicePrincipal = New-AzureADServicePrincipal `
    -AccountEnabled $true `
    -AppId $application.AppId `
    -AppRoleAssignmentRequired $true `
    -DisplayName $application.DisplayName `
    -Tags { WindowsAzureActiveDirectoryIntegratedApp }

# Create Service Principla Password Credential
Write-Host "Creating Service Principla Password Credential"
$password = ([System.Web.Security.Membership]::GeneratePassword(16, 5))
$startDate = [DateTime]::UtcNow
$endDate = [DateTime]::UtcNow.AddYears(100)
$servicePrincipalPasswordCredential = New-AzureADServicePrincipalPasswordCredential `
    -ObjectId $servicePrincipal.ObjectId `
    -Value $password `
    -StartDate $startDate
#-EndDate [DateTime]::UtcNow.AddYears(100)

# Add Service Principle as Security Group Member
Write-Host "Adding Service Principle as Member to Security Group"
Add-AzureADGroupMember `
    -ObjectId $securityGroup.ObjectId `
    -RefObjectId $servicePrincipal.ObjectId

# Add Data Landing Zone Owner as Service Principle Owner
Write-Host "Adding Data Landing Zone Owner as Owner to Service Principle"
Add-AzureADServicePrincipalOwner `
    -ObjectId $servicePrincipal.ObjectId `
    -RefObjectId $DataLandingZoneOwnerObjectId

# Add Data Landing Zone Owner as Application Owner
Write-Host "Adding Data Landing Zone Owner as Application Owner"
Add-AzureADApplicationOwner `
    -ObjectId $application.ObjectId `
    -RefObjectId $DataLandingZoneOwnerObjectId

# Add Data Landing Zone Owner as Security Group Owner
Write-Host "Adding Data Landing Zone Owner as Security Group Owner"
Add-AzureADGroupOwner `
    -ObjectId $securityGroup.ObjectId `
    -RefObjectId $DataLandingZoneOwnerObjectId

# Get Az Connection
Write-Host "Getting Az Connection"
Connect-AzAccount `
    -Tenant $connection.TenantID `
    -ApplicationId $connection.ApplicationID `
    -CertificateThumbprint $connection.CertificateThumbprint

# Set Az Context
Write-Host "Setting Az Context"
Set-AzContext `
    -Subscription $DataLandingZoneSubscriptionId

# Create Resource Group
Write-Host "Creating Resource Group"
$dataLandingZoneResourceGroupName = "${DataLandingZoneName}-rg"
New-AzResourceGroup `
    -Name $dataLandingZoneResourceGroupName `
    -Location $DataLandingZoneLocation `
    -Tag @{CostCode = "${DataLandingZoneCostCode}"; Owner = "${DataLandingZoneOwnerObjectId}" }

# Create Role Assignment to Resource Group
New-AzRoleAssignment `
    -ObjectId $securityGroup.ObjectId `
    -RoleDefinitionName "Contributor" `
    -ResourceGroupName $dataLandingZoneResourceGroupName

foreach ($dataLandingZoneSubnetId in $DataLandingZoneSubnetIds) {
    $dataLandingZoneSubnetIdObject = $dataLandingZoneSubnetId -split "/"
    $resourceGroupName = $dataLandingZoneSubnetIdObject[4]
    $virtualNetworkName = $dataLandingZoneSubnetIdObject[8]
    $subnetName = $dataLandingZoneSubnetIdObject[10]

    # Create Role Assignment to Subnet
    Write-Host "Creating Role Assignment to Subnet"
    New-AzRoleAssignment `
        -ObjectId $securityGroup.ObjectId `
        -RoleDefinitionName "Network Contributor" `
        -ResourceName $subnetName `
        -ResourceType Microsoft.Network/virtualNetworks/subnets `
        -ParentResource "virtualNetworks/${virtualNetworkName}" `
        -ResourceGroupName $resourceGroupName
}

# Create Output
Write-Host "Creating Output"
$output = @{
    "SecurityGroupObjectId"    = $securityGroup.ObjectId
    "ServicePrincipalObjectId" = $servicePrincipal.ObjectId
    "Password"                 = $password
}
Write-Output ( $output | ConvertTo-Json)

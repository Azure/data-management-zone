targetScope = 'subscription'

// Parameters
@description('Specifies the location for all resources.')
param location string

@allowed([
  'dev'
  'test'
  'prod'
])
@description('Specifies the environment of the deployment.')
param environment string

@minLength(3)
@maxLength(10)
@description('Specifies the prefix for all resources created in this deployment.')
param prefix string

@description('Specifies the address space of the vnet.')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Specifies the address space of the subnet that is use for Azure Firewall.')
param azureFirewallSubnetAddressPrefix string = '10.0.0.0/24'

@description('Specifies the address space of the subnet that is used for the services.')
param servicesSubnetAddressPrefix string = '10.0.1.0/24'

// Variables
var name = toLower('${prefix}-${environment}')
var tags = {
  Owner: 'Enterprise Scale Analytics'
  Project: 'Enterprise Scale Analytics'
  Environment: environment
  Toolkit: 'bicep'
  Name: name
}

// Network resources
resource networkResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-network'
  location: location
  tags: tags
  properties: {}
}

module networkServices 'modules/network.bicep' = {
  name: '${name}-network'
  scope: networkResourceGroup
  params: {
    prefix: name
    location: location
    tags: tags
    vnetAddressPrefix: vnetAddressPrefix
    azureFirewallSubnetAddressPrefix: azureFirewallSubnetAddressPrefix
    servicesSubnetAddressPrefix: servicesSubnetAddressPrefix
    dnsServerAdresses: []
    enableDnsAndFirewallDeployment: true
    firewallPrivateIp: ''
  }
}

// Private DNS zones
resource globalDnsResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-global-dns'
  location: location
  tags: tags
  properties: {}
}

module globalDnsZones 'modules/globalDns.bicep' = {
  name: '${name}-global-dns'
  scope: globalDnsResourceGroup
  params: {
    tags: tags
    vnetId: networkServices.outputs.vnetId
  }
}

// Governance resources
resource governanceResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-governance'
  location: location
  tags: tags
  properties: {}
}

module governanceResources 'modules/governance.bicep' = {
  name: '${name}-governance'
  scope: governanceResourceGroup
  params: {
    location: location
    prefix: name
    tags: tags
    subnetId: networkServices.outputs.serviceSubnet
    privateDnsZoneIdPurview: globalDnsZones.outputs.privateDnsZoneIdPurview
    privateDnsZoneIdBlob: globalDnsZones.outputs.privateDnsZoneIdBlob
    privateDnsZoneIdQueue: globalDnsZones.outputs.privateDnsZoneIdQueue
    privateDnsZoneIdNamespace: globalDnsZones.outputs.privateDnsZoneIdNamespace
    privateDnsZoneIdVault: globalDnsZones.outputs.privateDnsZoneIdVault
  }
}

// Container resources
resource containerResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-container'
  location: location
  tags: tags
  properties: {}
}

module containerResources 'modules/container.bicep' = {
  name: '${name}-container'
  scope: containerResourceGroup
  params: {
    location: location
    prefix: name
    tags: tags
    subnetId: networkServices.outputs.serviceSubnet
    privateDnsZoneIdContainerRegistry: globalDnsZones.outputs.privateDnsZoneIdContainerRegistry
  }
}

// Consumption resources
resource consumptionResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-consumption'
  location: location
  tags: tags
  properties: {}
}

module consumptionResources 'modules/consumption.bicep' = {
  name: '${name}-consumption'
  scope: consumptionResourceGroup
  params: {
    location: location
    prefix: name
    tags: tags
    subnetId: networkServices.outputs.serviceSubnet
    privateDnsZoneIdSynapse: globalDnsZones.outputs.privateDnsZoneIdSynapse
  }
}

// Automation services
resource automationResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-automation'
  location: location
  tags: tags
  properties: {}
}

// Management services
resource managementResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-mgmt'
  location: location
  tags: tags
  properties: {}
}

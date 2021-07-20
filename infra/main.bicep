// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

targetScope = 'subscription'

// General parameters
@description('Specifies the location for all resources.')
param location string
@allowed([
  'dev'
  'tst'
  'prd'
])
@description('Specifies the environment of the deployment.')
param environment string = 'dev'
@minLength(2)
@maxLength(10)
@description('Specifies the prefix for all resources created in this deployment.')
param prefix string
@description('Specifies the tags that you want to apply to all resources.')
param tags object = {}

// Network parameters
@description('Specifies whether firewall and private DNS Zones should be deployed.')
param enableDnsAndFirewallDeployment bool = true
@description('Specifies the address space of the vnet.')
param vnetAddressPrefix string = '10.0.0.0/16'
@description('Specifies the address space of the subnet that is use for Azure Firewall.')
param azureFirewallSubnetAddressPrefix string = '10.0.0.0/24'
@description('Specifies the address space of the subnet that is used for the services.')
param servicesSubnetAddressPrefix string = '10.0.1.0/24'
@description('Specifies the private IP address of the central firewall. Optional if `enableDnsAndFirewallDeployment` is set to `true`.')
param firewallPrivateIp string = '10.0.0.4'
@description('Specifies the private IP addresses of the dns servers. Optional if `enableDnsAndFirewallDeployment` is set to `true`.')
param dnsServerAdresses array = [
  '10.0.0.4'
]
@description('Specifies the resource ID of the Azure Firewall Policy. Optional parameter allows you to deploy Firewall rules to an existing Firewall Policy if `enableDnsAndFirewallDeployment` is set to `false`.')
param firewallPolicyId string = ''

// Private DNS Zone parameters
@description('Specifies the resource ID of the private DNS zone for Key Vault. Optional if `enableDnsAndFirewallDeployment` is set to `true`.')
param privateDnsZoneIdKeyVault string = ''
@description('Specifies the resource ID of the private DNS zone for Purview. Optional if `enableDnsAndFirewallDeployment` is set to `true`.')
param privateDnsZoneIdPurview string = ''
@description('Specifies the resource ID of the private DNS zone for Queue storage. Optional if `enableDnsAndFirewallDeployment` is set to `true`.')
param privateDnsZoneIdQueue string = ''
@description('Specifies the resource ID of the private DNS zone for Blob storage. Optional if `enableDnsAndFirewallDeployment` is set to `true`.')
param privateDnsZoneIdBlob string = ''
@description('Specifies the resource ID of the private DNS zone for EventHub namespaces. Optional if `enableDnsAndFirewallDeployment` is set to `true`.')
param privateDnsZoneIdNamespace string = ''
@description('Specifies the resource ID of the private DNS zone for Container Registry. Optional if `enableDnsAndFirewallDeployment` is set to `true`.')
param privateDnsZoneIdContainerRegistry string = ''
@description('Specifies the resource ID of the private DNS zone for Synapse. Optional if `enableDnsAndFirewallDeployment` is set to `true`.')
param privateDnsZoneIdSynapse string = ''

// Variables
var name = toLower('${prefix}-${environment}')
var tagsDefault = {
  Owner: 'Enterprise Scale Analytics'
  Project: 'Enterprise Scale Analytics'
  Environment: environment
  Toolkit: 'bicep'
  Name: name
}
var tagsJoined = union(tagsDefault, tags)

// Network resources
resource networkResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-network'
  location: location
  tags: tagsJoined
  properties: {}
}

module networkServices 'modules/network.bicep' = {
  name: 'networkServices'
  scope: networkResourceGroup
  params: {
    prefix: name
    location: location
    tags: tagsJoined
    vnetAddressPrefix: vnetAddressPrefix
    azureFirewallSubnetAddressPrefix: azureFirewallSubnetAddressPrefix
    servicesSubnetAddressPrefix: servicesSubnetAddressPrefix
    dnsServerAdresses: dnsServerAdresses
    enableDnsAndFirewallDeployment: enableDnsAndFirewallDeployment
    firewallPrivateIp: firewallPrivateIp
    firewallPolicyId: firewallPolicyId
  }
}

// Private DNS zones
resource globalDnsResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-global-dns'
  location: location
  tags: tagsJoined
  properties: {}
}

module globalDnsZones 'modules/services/privatednszones.bicep' = if (enableDnsAndFirewallDeployment) {
  name: 'globalDnsZones'
  scope: globalDnsResourceGroup
  params: {
    tags: tagsJoined
    vnetId: networkServices.outputs.vnetId
  }
}

// Governance resources
resource governanceResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-governance'
  location: location
  tags: tagsJoined
  properties: {}
}

module governanceResources 'modules/governance.bicep' = {
  name: 'governanceResources'
  scope: governanceResourceGroup
  params: {
    location: location
    prefix: name
    tags: tagsJoined
    subnetId: networkServices.outputs.serviceSubnet
    privateDnsZoneIdPurview: enableDnsAndFirewallDeployment ? globalDnsZones.outputs.privateDnsZoneIdPurview : privateDnsZoneIdPurview
    privateDnsZoneIdStorageBlob: enableDnsAndFirewallDeployment ? globalDnsZones.outputs.privateDnsZoneIdBlob : privateDnsZoneIdBlob
    privateDnsZoneIdStorageQueue: enableDnsAndFirewallDeployment ? globalDnsZones.outputs.privateDnsZoneIdQueue : privateDnsZoneIdQueue
    privateDnsZoneIdEventhubNamespace: enableDnsAndFirewallDeployment ? globalDnsZones.outputs.privateDnsZoneIdNamespace : privateDnsZoneIdNamespace
    privateDnsZoneIdKeyVault: enableDnsAndFirewallDeployment ? globalDnsZones.outputs.privateDnsZoneIdKeyVault : privateDnsZoneIdKeyVault
  }
}

// Container resources
resource containerResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-container'
  location: location
  tags: tagsJoined
  properties: {}
}

module containerResources 'modules/container.bicep' = {
  name: 'containerResources'
  scope: containerResourceGroup
  params: {
    location: location
    prefix: name
    tags: tagsJoined
    subnetId: networkServices.outputs.serviceSubnet
    privateDnsZoneIdContainerRegistry: enableDnsAndFirewallDeployment ? globalDnsZones.outputs.privateDnsZoneIdContainerRegistry : privateDnsZoneIdContainerRegistry
  }
}

// Consumption resources
resource consumptionResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-consumption'
  location: location
  tags: tagsJoined
  properties: {}
}

module consumptionResources 'modules/consumption.bicep' = {
  name: 'consumptionResources'
  scope: consumptionResourceGroup
  params: {
    location: location
    prefix: name
    tags: tagsJoined
    subnetId: networkServices.outputs.serviceSubnet
    privateDnsZoneIdSynapseprivatelinkhub: enableDnsAndFirewallDeployment ? globalDnsZones.outputs.privateDnsZoneIdSynapse : privateDnsZoneIdSynapse
    privateDnsZoneIdAnalysis: enableDnsAndFirewallDeployment ? globalDnsZones.outputs.privateDnsZoneIdAnalysis : ''
    privateDnsZoneIdPbiDedicated: enableDnsAndFirewallDeployment ? globalDnsZones.outputs.privateDnsZoneIdPbiDedicated : ''
    privateDnsZoneIdPowerQuery: enableDnsAndFirewallDeployment ? globalDnsZones.outputs.privateDnsZoneIdPowerQuery : ''
  }
}

// Automation services
resource automationResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-automation'
  location: location
  tags: tagsJoined
  properties: {}
}

// Management services
resource managementResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-mgmt'
  location: location
  tags: tagsJoined
  properties: {}
}

// Outputs
output vnetId string = networkServices.outputs.vnetId
output firewallPrivateIp string = networkServices.outputs.firewallPrivateIp
output purviewId string = governanceResources.outputs.purviewId
output privateDnsZoneIdKeyVault string = enableDnsAndFirewallDeployment ? globalDnsZones.outputs.privateDnsZoneIdKeyVault : ''
output privateDnsZoneIdDataFactory string = enableDnsAndFirewallDeployment ? globalDnsZones.outputs.privateDnsZoneIdDataFactory : ''
output privateDnsZoneIdDataFactoryPortal string = enableDnsAndFirewallDeployment ? globalDnsZones.outputs.privateDnsZoneIdDataFactoryPortal : ''
output privateDnsZoneIdBlob string = enableDnsAndFirewallDeployment ? globalDnsZones.outputs.privateDnsZoneIdBlob : ''
output privateDnsZoneIdDfs string = enableDnsAndFirewallDeployment ? globalDnsZones.outputs.privateDnsZoneIdDfs : ''
output privateDnsZoneIdSqlServer string = enableDnsAndFirewallDeployment ? globalDnsZones.outputs.privateDnsZoneIdSqlServer : ''
output privateDnsZoneIdMySqlServer string = enableDnsAndFirewallDeployment ? globalDnsZones.outputs.privateDnsZoneIdMySqlServer : ''
output privateDnsZoneIdNamespace string = enableDnsAndFirewallDeployment ? globalDnsZones.outputs.privateDnsZoneIdNamespace : ''
output privateDnsZoneIdSynapseDev string = enableDnsAndFirewallDeployment ? globalDnsZones.outputs.privateDnsZoneIdSynapseDev : ''
output privateDnsZoneIdSynapseSql string = enableDnsAndFirewallDeployment ? globalDnsZones.outputs.privateDnsZoneIdSynapseSql : ''

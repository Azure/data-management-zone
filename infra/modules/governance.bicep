// This template is used as a module from the main.bicep template. 
// The module contains a template to create the governance services.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
param privateDnsZoneIdPurview string
param privateDnsZoneIdStorageBlob string
param privateDnsZoneIdStorageQueue string
param privateDnsZoneIdEventhubNamespace string
param privateDnsZoneIdKeyVault string

// Variables
var purview001Name = '${prefix}-purview001'
var keyvault001Name = '${prefix}-vault001'

// Resources
module purview001 'services/purview.bicep' = {
  name: 'purview001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    purviewName: purview001Name
    privateDnsZoneIdPurview: privateDnsZoneIdPurview
    privateDnsZoneIdStorageBlob: privateDnsZoneIdStorageBlob
    privateDnsZoneIdStorageQueue: privateDnsZoneIdStorageQueue
    privateDnsZoneIdEventhubNamespace: privateDnsZoneIdEventhubNamespace
  }
}

module keyVault001 'services/keyvault.bicep' = {
  name: 'keyVault001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    keyvaultName: keyvault001Name
    privateDnsZoneIdKeyVault: privateDnsZoneIdKeyVault
  }
}

resource purviewKeyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: '${guid(uniqueString('${resourceGroup().id}${purview001Name}${keyvault001Name}'))}'
  properties: {
    principalId: purview001.outputs.purviewPrincipalId
    principalType: 'MSI'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
  }
}

// Outputs

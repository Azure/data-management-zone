// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// The module contains a template to create a role assignment to a KeyVault.
targetScope = 'resourceGroup'

// Parameters
param purviewId string
param keyVaultId string

// Variables
var keyVaultName = length(split(keyVaultId, '/')) >= 9 ? last(split(keyVaultId, '/')) : 'incorrectSegmentLength'
var purviewSubscriptionId = length(split(purviewId, '/')) >= 9 ? split(purviewId, '/')[2] : subscription().subscriptionId
var purviewResourceGroupName = length(split(purviewId, '/')) >= 9 ? split(purviewId, '/')[4] : resourceGroup().name
var purviewName = length(split(purviewId, '/')) >= 9 ? last(split(purviewId, '/')) : 'incorrectSegmentLength'

// Resources
resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: keyVaultName
}

resource purview 'Microsoft.Purview/accounts@2020-12-01-preview' existing = {
  name: purviewName
  scope: resourceGroup(purviewSubscriptionId, purviewResourceGroupName)
}

resource purviewRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(uniqueString(keyVault.id, purview.id))
  scope: keyVault
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: purview.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs

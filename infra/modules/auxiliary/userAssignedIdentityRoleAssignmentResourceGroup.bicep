// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// The module contains a template to create a role assignment of a useer assigned identity to a resource group.
targetScope = 'resourceGroup'

// Parameters
param userAssignedIdentityId string

// Variables
var userAssignedIdentitySubscriptionId = length(split(userAssignedIdentityId, '/')) >= 9 ? split(userAssignedIdentityId, '/')[2] : subscription().subscriptionId
var userAssignedIdentityResourceGroupName = length(split(userAssignedIdentityId, '/')) >= 9 ? split(userAssignedIdentityId, '/')[4] : resourceGroup().name
var userAssignedIdentityName = length(split(userAssignedIdentityId, '/')) >= 9 ? last(split(userAssignedIdentityId, '/')) : 'incorrectSegmentLength'

// Resources
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: userAssignedIdentityName
  scope:  resourceGroup(userAssignedIdentitySubscriptionId, userAssignedIdentityResourceGroupName)
}

resource resourceGroupRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(uniqueString(resourceGroup().id, userAssignedIdentity.id))
  scope: resourceGroup()
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used as a module from the main.bicep template. 
// The module contains a template to create the automation services.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param purviewId string
param purviewRootCollectionAdminObjectIds array = []

// Variables
var userAssignedIdentity001Name = '${prefix}-uai001'
var purviewSubscriptionId = length(split(purviewId, '/')) >= 9 ? split(purviewId, '/')[2] : subscription().subscriptionId
var purviewResourceGroupName = length(split(purviewId, '/')) >= 9 ? split(purviewId, '/')[4] : resourceGroup().name

// Resources
module userAssignedIdentity001 'services/userassignedidentity.bicep' = {
  name: 'userAssignedIdentity001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    userAssignedIdentityName: userAssignedIdentity001Name
  }
}

module userAssignedIdentity001RoleAssignmentResourceGroup 'auxiliary/userAssignedIdentityRoleAssignmentResourceGroup.bicep' = {
  name: 'userAssignedIdentity001RoleAssignmentPurview'
  scope:  resourceGroup(purviewSubscriptionId, purviewResourceGroupName)
  params: {
    userAssignedIdentityId: userAssignedIdentity001.outputs.userAssignedIdentityId
  }
}

module purviewSetup 'auxiliary/purviewSetup.bicep' = {
  name: 'purviewSetup'
  scope: resourceGroup()
  dependsOn: [
    userAssignedIdentity001RoleAssignmentResourceGroup
  ]
  params: {
    location: location
    tags: tags
    userAssignedIdentityId: userAssignedIdentity001.outputs.userAssignedIdentityId
    purviewId: purviewId
    purviewRootCollectionAdminObjectIds: purviewRootCollectionAdminObjectIds
  }
}

// Outputs

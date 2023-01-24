// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a User Assigned Identity.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param userAssignedIdentityName string

// Variables

// Resources
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: userAssignedIdentityName
  location: location
  tags: tags
}

// Outputs
output userAssignedIdentityId string = userAssignedIdentity.id

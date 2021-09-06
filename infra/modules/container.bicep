// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used as a module from the main.bicep template. 
// The module contains a template to create the container services.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
param privateDnsZoneIdContainerRegistry string = ''

// Variables
var containerRegistry001Name = '${prefix}-containerregistry001'

// Resources
module containerRegistry001 'services/containerregistry.bicep' = {
  name: 'containerRegistry001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    containerRegistryName: containerRegistry001Name
    privateDnsZoneIdContainerRegistry: privateDnsZoneIdContainerRegistry
  }
}

// Outputs

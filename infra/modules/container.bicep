// This template is used as a module from the main.bicep template. 
// The module contains a template to create the container services.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
param privateDnsZoneIdContainerRegistry string

// Variables

// Resources
module containerRegistry001 'services/containerregistry.bicep' = {
  name: 'containerRegistry001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    containerRegistryName: '${prefix}-containerregistry001'
    privateDnsZoneIdContainerRegistry: privateDnsZoneIdContainerRegistry
  }
}

// Outputs

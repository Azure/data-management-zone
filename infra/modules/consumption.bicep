// This template is used as a module from the main.bicep template. 
// The module contains a template to create consumption resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
param privateDnsZoneIdSynapseprivatelinkhub string

// Variables

// Resources
module synapsePrivateLinkHub001 'services/synapseprivatelinkhub.bicep' = {
  name: 'synapsePrivateLinkHub001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    synapsePrivatelinkHubName: '${prefix}-synapseplhub001'
    privateDnsZoneIdSynapseprivatelinkhub: privateDnsZoneIdSynapseprivatelinkhub
  }
}

// Outputs

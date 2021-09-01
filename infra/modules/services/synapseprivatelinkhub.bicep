// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a Synapse Private Link Hub.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param subnetId string
param synapsePrivatelinkHubName string
param privateDnsZoneIdSynapseprivatelinkhub string

// Variables
var synapsePrivatelinkHubNameCleaned = replace(synapsePrivatelinkHubName, '-', '')
var synapsePrivatelinkHubPrivateEndpointName = '${synapsePrivatelinkHub.name}-private-endpoint'

// Resources
resource synapsePrivatelinkHub 'Microsoft.Synapse/privateLinkHubs@2021-03-01' = {
  name: synapsePrivatelinkHubNameCleaned
  location: location
  tags: tags
  properties: {}
}

resource synapsePrivatelinkHubPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: synapsePrivatelinkHubPrivateEndpointName
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: synapsePrivatelinkHubPrivateEndpointName
        properties: {
          groupIds: [
            'web'
          ]
          privateLinkServiceId: synapsePrivatelinkHub.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource synapsePrivatelinkHubPrivateEndpointARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = if (!empty(privateDnsZoneIdSynapseprivatelinkhub)) {
  parent: synapsePrivatelinkHubPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${synapsePrivatelinkHubPrivateEndpoint.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdSynapseprivatelinkhub
        }
      }
    ]
  }
}

// Outputs

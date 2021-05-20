// This template is used as a module from the main.bicep template. 
// The module contains a template to create consumption resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
param privateDnsZoneIdSynapse string

// Variables
var synapsePrivateLinkHub001PrivateEndpointName = '${synapsePrivateLinkHub001.name}-private-endpoint'

// Resources
resource synapsePrivateLinkHub001 'Microsoft.Synapse/privateLinkHubs@2021-03-01' = {
  name: '${prefix}synapseprivatelinkhub001'
  location: location
  tags: tags
  properties: {}
}

resource synapsePrivateLinkHub001PrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: synapsePrivateLinkHub001PrivateEndpointName
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: synapsePrivateLinkHub001PrivateEndpointName
        properties: {
          groupIds: [
            'web'
          ]
          privateLinkServiceId: synapsePrivateLinkHub001.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource synapsePrivateLinkHub001PrivateEndpointARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${synapsePrivateLinkHub001PrivateEndpoint.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${synapsePrivateLinkHub001PrivateEndpoint.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdSynapse
        }
      }
    ]
  }
}

// Outputs

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
var containerRegistry001PrivateEndpointName = '${containerRegistry001.name}-private-endpoint'

// Resources
resource containerRegistry001 'Microsoft.ContainerRegistry/registries@2020-11-01-preview' = {
  name: replace('${prefix}-containerregistry001', '-', '')
  location: location
  tags: tags
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: false
    anonymousPullEnabled: true
    dataEndpointEnabled: false
    networkRuleBypassOptions: 'None'
    networkRuleSet: {
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    policies: {
      quarantinePolicy: {
        status: 'enabled'
      }
      retentionPolicy: {
        status: 'enabled'
        days: 7
      }
      trustPolicy: {
        status: 'disabled'
        type: 'Notary'
      }
    }
    publicNetworkAccess: 'Disabled'
    zoneRedundancy: 'Enabled'
  }
}

resource containerRegistry001PrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: containerRegistry001PrivateEndpointName
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: containerRegistry001PrivateEndpointName
        properties: {
          groupIds: [
            'registry'
          ]
          privateLinkServiceId: containerRegistry001.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource containerRegistry001PrivateEndpointARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${containerRegistry001PrivateEndpoint.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${containerRegistry001PrivateEndpoint.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdContainerRegistry
        }
      }
    ]
  }
}

// Outputs

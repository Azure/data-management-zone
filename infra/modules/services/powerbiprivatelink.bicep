// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a Power BI Private Link Service.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param subnetId string
param powerbiPrivateLinkName string
param privateDnsZoneIdAnalysis string = ''
param privateDnsZoneIdPbiDedicated string = ''
param privateDnsZoneIdPowerQuery string = ''

// Variables
var powerbiPrivateLinkPrivateEndpointName = '${powerbiPrivateLink.name}-private-endpoint'

// Resources
resource powerbiPrivateLink 'Microsoft.PowerBI/privateLinkServicesForPowerBI@2020-06-01' = {
  name: powerbiPrivateLinkName
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
  }
}

resource powerbiPrivateLinkPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: powerbiPrivateLinkPrivateEndpointName
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: powerbiPrivateLinkPrivateEndpointName
        properties: {
          groupIds: [
            'tenant'
          ]
          privateLinkServiceId: powerbiPrivateLink.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource powerbiPrivateLinkPrivateEndpointARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = if (!empty(privateDnsZoneIdAnalysis) && !empty(privateDnsZoneIdPbiDedicated) && !empty(privateDnsZoneIdPowerQuery)) {
  parent: powerbiPrivateLinkPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${powerbiPrivateLinkPrivateEndpoint.name}-analysis-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdAnalysis
        }
      }
      {
        name: '${powerbiPrivateLinkPrivateEndpoint.name}-pbidedicated-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdPbiDedicated
        }
      }
      {
        name: '${powerbiPrivateLinkPrivateEndpoint.name}-powerquery-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdPowerQuery
        }
      }
    ]
  }
}

// Outputs

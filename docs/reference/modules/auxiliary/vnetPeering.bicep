// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// The module contains a template to create vnet peering between two vnets.
targetScope = 'resourceGroup'

// Parameters
param sourceVnetId string
param destinationVnetId string

// Variables
var sourceVnetName = length(split(sourceVnetId, '/')) >= 9 ? last(split(sourceVnetId, '/')) : 'incorrectSegmentLength'
var destinationVnetName = length(split(destinationVnetId, '/')) >= 9 ? last(split(destinationVnetId, '/')) : 'incorrectSegmentLength'

// Resources
resource dataLandingZoneToDataLandingZoneVnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-11-01' = if (sourceVnetId != destinationVnetId) {
  name: '${sourceVnetName}/${destinationVnetName}'
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    allowVirtualNetworkAccess: true
    peeringState: 'Connected'
    remoteVirtualNetwork: {
      id: destinationVnetId
    }
    useRemoteGateways: false
  }
}

// Outputs

// This template is used as a module from the network.bicep template. 
// The module contains a template to create vnet peering from the data management zone vnet.
targetScope = 'resourceGroup'

// Parameters
param sourceVnetId string
param destinationVnetId string

// Variables
var sourceVnetName = last(split(sourceVnetId, '/'))
var destinationVnetName = last(split(destinationVnetId, '/'))

// Resources
resource dataManagementZoneDataLandingZoneVnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-11-01' = if (sourceVnetId != destinationVnetId) {
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

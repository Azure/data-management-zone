// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used as a module from the main.bicep template. 
// The module contains a template to create consumption resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
param privateDnsZoneIdSynapseprivatelinkhub string = ''
param privateDnsZoneIdAnalysis string = ''
param privateDnsZoneIdPbiDedicated string = ''
param privateDnsZoneIdPowerQuery string = ''

// Variables
var synapsePrivatelinkHub001Name = '${prefix}-synapseplhub001'
var powerbiPrivateLink001Name = '${prefix}-powerbipl001'

// Resources
module synapsePrivateLinkHub001 'services/synapseprivatelinkhub.bicep' = {
  name: 'synapsePrivateLinkHub001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    synapsePrivatelinkHubName: synapsePrivatelinkHub001Name
    privateDnsZoneIdSynapseprivatelinkhub: privateDnsZoneIdSynapseprivatelinkhub
  }
}

// module powerbiPrivateLink001 'services/powerbiprivatelink.bicep' = {  // Uncomment if you want to enable private connectivity to your power bi tenant
//   name: 'powerbiPrivateLink001'
//   scope: resourceGroup()
//   params: {
//     location: location
//     tags: tags
//     subnetId: subnetId
//     powerbiPrivateLinkName: powerbiPrivateLink001Name
//     privateDnsZoneIdAnalysis: privateDnsZoneIdAnalysis
//     privateDnsZoneIdPbiDedicated: privateDnsZoneIdPbiDedicated
//     privateDnsZoneIdPowerQuery: privateDnsZoneIdPowerQuery
//   }
// }

// Outputs

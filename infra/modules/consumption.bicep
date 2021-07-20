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
param privateDnsZoneIdSynapseprivatelinkhub string
param privateDnsZoneIdAnalysis string
param privateDnsZoneIdPbiDedicated string
param privateDnsZoneIdPowerQuery string

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

// module powerbiPrivateLink001 'services/powerbiprivatelink.bicep' = {  // Uncomment if you want to enable private connectivity to your power bi tenant
//   name: 'powerbiPrivateLink001'
//   scope: resourceGroup()
//   params: {
//     location: location
//     tags: tags
//     subnetId: subnetId
//     powerbiPrivateLinkName: '${prefix}-powerbipl001'
//     privateDnsZoneIdAnalysis: privateDnsZoneIdAnalysis
//     privateDnsZoneIdPbiDedicated: privateDnsZoneIdPbiDedicated
//     privateDnsZoneIdPowerQuery: privateDnsZoneIdPowerQuery
//   }
// }

// Outputs

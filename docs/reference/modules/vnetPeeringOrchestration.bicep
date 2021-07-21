// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// The module contains a template to orchestrate vnet peering deployments.
targetScope = 'subscription'

// Parameters
param sourceVnetId string
param destinationVnetIds array

// Variables
var sourceVnetSubscriptionId = split(sourceVnetId, '/')[2]
var sourceVnetResourceGroupName = split(sourceVnetId, '/')[4]

// Resources
module vnetPeering 'auxiliary/vnetPeering.bicep' = [for (destinationVnetId, index) in destinationVnetIds: {
  name: 'vnetPeering${index}'
  scope: resourceGroup(sourceVnetSubscriptionId, sourceVnetResourceGroupName)
  params: {
    sourceVnetId: sourceVnetId
    destinationVnetId: destinationVnetId
  }
}]

// Outputs

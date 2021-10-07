/ Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a Self-hosted Integration Runtime.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param subnetId string
param vmssName string
param vmssSkuName string = 'Standard_DS2_v2'
param vmssSkuTier string = 'Standard'
param vmssSkuCapacity int = 1
param administratorUsername string = 'VmssMainUser'
@secure()
param administratorPassword string

// Variables
var loadbalancerName = '${vmssName}-lb'

// Resources
resource scalesetagent 'Microsoft.Compute/virtualMachineScaleSets@2021-04-01' = {
  name: vmssName
  location: location
  tags: tags
  
  properties: {
    
  }
}

// Outputs

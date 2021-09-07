// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used as a module from the main.bicep template. 
// The module contains a template to deploy a bastion host.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param bastionName string
param subnetId string

// Variables
var publicIpName = '${bastionName}-pip'

// Resources
resource publicip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: publicIpName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2021-02-01' = {
  name: bastionName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    dnsName: bastionName
    ipConfigurations: [
      {
        name: 'ipConfiguration'
        properties: {
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: publicip.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// Outputs

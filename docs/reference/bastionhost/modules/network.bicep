// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used as a module from the main.bicep template. 
// The module contains a template to deploy a bastion host.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param vnetName string
param bastionSubnetAddressPrefix string = '10.1.10.0/24'
param jumpboxSubnetAddressPrefix string = '10.1.11.0/24'
param defaultNsgId string
param defaultRouteTableId string

// Variables

// Resources
resource bastionNsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: '${prefix}-bastion-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowHttpsInbound'
        properties: {
          description: 'Required for HTTPS inbound communication of connecting user.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowGatewayManagerInbound'
        properties: {
          description: 'Required for the control plane, that is, Gateway Manager to be able to talk to Azure Bastion.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowAzureLoadBalancerInbound'
        properties: {
          description: 'Required for the control plane, that is, Gateway Manager to be able to talk to Azure Bastion.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 140
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowBastionCommunicationInbound'
        properties: {
          description: 'Required for data plane communication between the underlying components of Azure Bastion.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: ''
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 150
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: [
            '5701'
            '8080'
          ]
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowSshRdpOutbound'
        properties: {
          description: 'Required for SSH and RDP outbound connectivity.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: ''
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: [
            '22'
            '3389'
          ]
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowAzureCloudOutbound'
        properties: {
          description: 'Required for Azure Cloud outbound connectivity (Logs and Metrics).'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowBastionCommunicationOutbound'
        properties: {
          description: 'Required for data plane communication between the underlying components of Azure Bastion.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: ''
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: [
            '5701'
            '8080'
          ]
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowGetSessionInformationOutbound'
        properties: {
          description: 'Required for session and certificate validation..'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: vnetName
}

resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  parent: vnet
  name: 'AzureBastionSubnet'
  properties: {
    addressPrefix: bastionSubnetAddressPrefix
    addressPrefixes: []
    networkSecurityGroup: {
      id: bastionNsg.id
    }
    // routeTable: {  // Route Tables cannot be yet added to Bastion Host subnets yet
    //   id: ''
    // }
    delegations: []
    ipAllocations: []
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    serviceEndpointPolicies: []
    serviceEndpoints: []
  }
}

resource jumpboxSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  parent: vnet
  name: 'JumpboxSubnet'
  dependsOn: [
    bastionSubnet
  ]
  properties: {
    addressPrefix: jumpboxSubnetAddressPrefix
    addressPrefixes: []
    networkSecurityGroup: {
      id: defaultNsgId
    }
    routeTable: {
      id: defaultRouteTableId
    }
    delegations: []
    ipAllocations: []
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    serviceEndpointPolicies: []
    serviceEndpoints: []
  }
}

// Outputs
output bastionSubnetId string = bastionSubnet.id
output jumpboxSubnetId string = jumpboxSubnet.id

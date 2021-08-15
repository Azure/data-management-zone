// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used as a module from the main.bicep template.
// The module contains a template to create network resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param firewallPrivateIp string = '10.0.0.4'
param dnsServerAdresses array = [
  '10.0.0.4'
]
param vnetAddressPrefix string = '10.0.0.0/16'
param azureFirewallSubnetAddressPrefix string = '10.0.0.0/24'
param servicesSubnetAddressPrefix string = '10.0.1.0/24'
param enableDnsAndFirewallDeployment bool = true
param firewallPolicyId string = ''

// Variables
var azureFirewallSubnetName = 'AzureFirewallSubnet'
var servicesSubnetName = 'ServicesSubnet'
var firewallPolicySubscriptionId = length(split(firewallPolicyId, '/')) >= 9 ? split(firewallPolicyId, '/')[2] : subscription().subscriptionId
var firewallPolicyResourceGroupName = length(split(firewallPolicyId, '/')) >= 9 ? split(firewallPolicyId, '/')[4] : resourceGroup().name
var firewallPolicyName = length(split(firewallPolicyId, '/')) >= 9 ? last(split(firewallPolicyId, '/')) : 'incorrectSegmentLength'

// Resources
resource routeTable 'Microsoft.Network/routeTables@2020-11-01' = {
  name: '${prefix}-routetable'
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: false
    routes: []
  }
}

resource routeTableDefaultRoute 'Microsoft.Network/routeTables/routes@2020-11-01' = {
  name: 'to-firewall-default'
  parent: routeTable
  properties: {
    addressPrefix: '0.0.0.0/0'
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: enableDnsAndFirewallDeployment ? firewall.properties.ipConfigurations[0].properties.privateIPAddress : firewallPrivateIp
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: '${prefix}-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: []
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: '${prefix}-vnet'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    dhcpOptions: {
      dnsServers: enableDnsAndFirewallDeployment ? [] : dnsServerAdresses
    }
    enableDdosProtection: false
    subnets: [
      {
        name: azureFirewallSubnetName
        properties: {
          addressPrefix: azureFirewallSubnetAddressPrefix
          addressPrefixes: []
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpointPolicies: []
          serviceEndpoints: []
        }
      }
      {
        name: servicesSubnetName
        properties: {
          addressPrefix: servicesSubnetAddressPrefix
          addressPrefixes: []
          networkSecurityGroup: {
            id: nsg.id
          }
          routeTable: {
            id: routeTable.id
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          serviceEndpointPolicies: []
          serviceEndpoints: []
        }
      }
    ]
  }
}

resource publicIpPrefixes 'Microsoft.Network/publicIPPrefixes@2020-11-01' = if (enableDnsAndFirewallDeployment) {
  name: '${prefix}-publicipprefix'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    prefixLength: 30
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-11-01' = if (enableDnsAndFirewallDeployment) {
  name: '${prefix}-publicip001'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: '${prefix}-publicip001'
    }
    publicIPPrefix: {
      id: publicIpPrefixes.id
    }
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2020-11-01' = if (enableDnsAndFirewallDeployment) {
  name: '${prefix}-firewallpolicy'
  location: location
  tags: tags
  properties: {
    intrusionDetection: {
      mode: 'Deny'
      configuration: {
        bypassTrafficSettings: []
        signatureOverrides: []
      }
    }
    threatIntelMode: 'Deny'
    threatIntelWhitelist: {
      fqdns: []
      ipAddresses: []
    }
    sku: {
      tier: 'Premium'
    }
    dnsSettings: {
      enableProxy: true
      servers: []
    }
  }
}

module firewallPolicyRules 'services/firewallPolicyRules.bicep' = if (enableDnsAndFirewallDeployment) {
  name: '${prefix}-firewallpolicy-rules'
  scope: resourceGroup()
  dependsOn: [
    firewallPolicy
  ]
  params: {
    firewallPolicyName: firewallPolicy.name
  }
}

module firewallPolicyRulesToExistingFirewallPolicy 'services/firewallPolicyRules.bicep' = if (!enableDnsAndFirewallDeployment && !empty(firewallPolicyId)) {
  name: '${prefix}-firewallpolicy-rules-toExistingFirewallPolicy'
  scope: resourceGroup(firewallPolicySubscriptionId, firewallPolicyResourceGroupName)
  params: {
    firewallPolicyName: firewallPolicyName
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2020-11-01' = if (enableDnsAndFirewallDeployment) {
  name: '${prefix}-firewall'
  dependsOn: [
    firewallPolicyRules
  ]
  location: location
  tags: tags
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Premium'
    }
    ipConfigurations: [
      {
        name: 'ipConfiguration001'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
          subnet: {
            id: vnet.properties.subnets[0].id
          }
        }
      }
    ]
    firewallPolicy: {
      id: firewallPolicy.id
    }
  }
}

// Outputs
output vnetId string = vnet.id
output serviceSubnet string = vnet.properties.subnets[1].id
output firewallPrivateIp string = enableDnsAndFirewallDeployment ? firewall.properties.ipConfigurations[0].properties.privateIPAddress : firewallPrivateIp

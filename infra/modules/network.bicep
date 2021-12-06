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
param virtualNetworkManagerManagementGroupScopes array = []
param virtualNetworkManagerSubscriptionScopes array = []

// Variables
var azureFirewallSubnetName = 'AzureFirewallSubnet'
var servicesSubnetName = 'ServicesSubnet'
var virtualNetworkManagerName = '${prefix}-vnm'
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

resource publicIpPrefixes 'Microsoft.Network/publicIPPrefixes@2020-11-01' = if(enableDnsAndFirewallDeployment) {
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

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-11-01' = if(enableDnsAndFirewallDeployment) {
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

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2020-11-01' = if(enableDnsAndFirewallDeployment) {
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

module firewallPolicyRules 'services/firewallPolicyRules.bicep' = if(enableDnsAndFirewallDeployment) {
  name: '${prefix}-firewallpolicy-rules'
  scope: resourceGroup()
  dependsOn: [
    firewallPolicy
  ]
  params: {
    firewallPolicyName: firewallPolicy.name
  }
}

module firewallPolicyRulesToExistingFirewallPolicy 'services/firewallPolicyRules.bicep' = if(!enableDnsAndFirewallDeployment && !empty(firewallPolicyId)) {
  name: '${prefix}-firewallpolicy-rules-toExistingFirewallPolicy'
  scope: resourceGroup(firewallPolicySubscriptionId, firewallPolicyResourceGroupName)
  params: {
    firewallPolicyName: firewallPolicyName
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2020-11-01' = if(enableDnsAndFirewallDeployment) {
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

resource virtualNetworkManager 'Microsoft.Network/networkManagers@2021-02-01-preview' = {
  name: virtualNetworkManagerName
  location: location
  tags: tags
  properties: {
    description: 'Network Manager for ESA Mesh Network Architecture'
    displayName: virtualNetworkManagerName
    networkManagerScopeAccesses: [
      'Connectivity'
      'SecurityAdmin'
      'SecurityUser'
    ]
    networkManagerScopes: {
      managementGroups: union(array(null), virtualNetworkManagerManagementGroupScopes)
      subscriptions: union(array(subscription().id), virtualNetworkManagerSubscriptionScopes)
    }
  }
}

resource virtualNetworkManagerDevNetworkGroup 'Microsoft.Network/networkManagers/networkGroups@2021-02-01-preview' = {
  parent: virtualNetworkManager
  name: 'EnterpriseScaleAnalyticsDevNetworkGroup'
  properties: {
    description: 'Development Group for Enterprise-Scale Analytics'
    displayName: 'Enterprise-Scale Analytics Dev Network Group'
    conditionalMembership: '{ "allOf": [ { "field": "tags[\'Environment\']", "equals": "dev" }, { "value": "[resourceGroup().Name]", "contains": "-network" } ] }'
    groupMembers: []
    memberType: ''
  }
}

resource virtualNetworkManagerTestNetworkGroup 'Microsoft.Network/networkManagers/networkGroups@2021-02-01-preview' = {
  parent: virtualNetworkManager
  name: 'EnterpriseScaleAnalyticsTestNetworkGroup'
  properties: {
    description: 'Test Group for Enterprise-Scale Analytics'
    displayName: 'Enterprise-Scale Analytics Test Network Group'
    conditionalMembership: '{ "allOf": [ { "field": "tags[\'Environment\']", "equals": "tst" }, { "value": "[resourceGroup().Name]", "contains": "-network" } ] }'
    groupMembers: []
    memberType: ''
  }
}

resource virtualNetworkManagerProdNetworkGroup 'Microsoft.Network/networkManagers/networkGroups@2021-02-01-preview' = {
  parent: virtualNetworkManager
  name: 'EnterpriseScaleAnalyticsProdNetworkGroup'
  properties: {
    description: 'Production Group for Enterprise-Scale Analytics'
    displayName: 'Enterprise-Scale Analytics Prod Network Group'
    conditionalMembership: '{ "allOf": [ { "field": "tags[\'Environment\']", "equals": "prd" }, { "value": "[resourceGroup().Name]", "contains": "-network" } ] }'
    groupMembers: []
    memberType: ''
  }
}

resource virtualNetworkManagerConnectivityConfiguration 'Microsoft.Network/networkManagers/connectivityConfigurations@2021-02-01-preview' = {
  parent: virtualNetworkManager
  name: 'EnterpriseScaleAnalyticsConnectivityConfig'
  properties: {
    connectivityTopology: 'Mesh'
    appliesToGroups: [
      {
        groupConnectivity: 'DirectlyConnected'
        isGlobal: 'False'
        networkGroupId: virtualNetworkManagerDevNetworkGroup.id
      }
      {
        groupConnectivity: 'DirectlyConnected'
        isGlobal: 'False'
        networkGroupId: virtualNetworkManagerTestNetworkGroup.id
      }
      {
        groupConnectivity: 'DirectlyConnected'
        isGlobal: 'False'
        networkGroupId: virtualNetworkManagerProdNetworkGroup.id
      }
    ]
    deleteExistingPeering: 'True'
    description: 'Enterprise-Scale Analytics Mesh Network Topology'
    displayName: 'Enterprise-Scale Analytics Connectivity Config'
    hubs: []
    isGlobal: 'False'
  }
}

// module dnsforwarder001 'services/dnsforwarder.bicep' = {  // Uncomment if you want to use a VMSS as DNS Forwarder instead of the Azure Firewall
//   name: 'dnsforwarder001'
//   scope: resourceGroup()
//   params: {
//     location: location
//     tags: tags
//     subnetId: vnet.properties.subnets[1].id
//     dnsForwarderName: dnsForwarder001Name
//     vmssSkuName: vmssSkuName
//     vmssSkuTier: vmssSkuTier
//     vmssSkuCapacity: vmssSkuCapacity
//     vmssAdmininstratorUsername: vmssAdmininstratorUsername
//     vmssAdministratorPublicSshKey: vmssAdministratorPublicSshKey
//   }
// }

// Outputs
output vnetId string = vnet.id
output serviceSubnet string = vnet.properties.subnets[1].id
output firewallPrivateIp string = enableDnsAndFirewallDeployment ? firewall.properties.ipConfigurations[0].properties.privateIPAddress : firewallPrivateIp

// This template is used as a module from the main.bicep template. 
// The module contains a template to create network resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param firewallPrivateIp string = '10.0.0.4'
param dnsServerAdresses array = []
param vnetAddressPrefix string
param azureFirewallSubnetAddressPrefix string
param servicesSubnetAddressPrefix string
param enableDnsAndFirewallDeployment bool

// Variables
var azureFirewallSubnetName = 'AzureFirewallSubnet'
var servicesSubnetName = 'ServicesSubnet'

// Resources
resource routeTable 'Microsoft.Network/routeTables@2020-11-01' = {
  name: '${prefix}-routetable'
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'to-firewall-default'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewall.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
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
      dnsServers: dnsServerAdresses
    }
    enableDdosProtection: false
    subnets: []
  }
}

resource azureFirewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  name: '${vnet.name}/${azureFirewallSubnetName}'
  properties: {
    addressPrefix: azureFirewallSubnetAddressPrefix
    addressPrefixes: []
    networkSecurityGroup: {
      id: nsg.id
    }
    delegations: []
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    serviceEndpointPolicies: []
    serviceEndpoints: []
  }
}

resource servicesSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  name: '${vnet.name}/${servicesSubnetName}'
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

resource publicIpPrefixes 'Microsoft.Network/publicIPPrefixes@2020-11-01' = {
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

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
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

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2020-11-01' = {
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
      requireProxyForNetworkRules: true
    }
  }
}

module firewallPolicyRules 'firewallPolicyRules.bicep' = {
  name: '${prefix}-firewallpolicy-rules'
  scope: resourceGroup()
  params: {
    firewallPolicyName: firewallPolicy.name
    location: location
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2020-11-01' = {
  name: '${prefix}-firewallpolicy'
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
            id: azureFirewallSubnet.id
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
output serviceSubnet string = servicesSubnet.id

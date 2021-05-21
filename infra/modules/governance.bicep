// This template is used as a module from the main.bicep template. 
// The module contains a template to create the governance services.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
param privateDnsZoneIdPurview string
param privateDnsZoneIdBlob string
param privateDnsZoneIdQueue string
param privateDnsZoneIdNamespace string
param privateDnsZoneIdVault string

// Variables
var purviewPrivateEndpointNamePortal = '${purview001.name}-portal-private-endpoint'
var purviewPrivateEndpointNameAccount = '${purview001.name}-account-private-endpoint'
var purviewPrivateEndpointNameBlob = '${purview001.name}-blob-private-endpoint'
var purviewPrivateEndpointNameQueue = '${purview001.name}-queue-private-endpoint'
var purviewPrivateEndpointNameNamespace = '${purview001.name}-namespace-private-endpoint'
var purviewRegions = [
  'brazilsouth'
  'canadacentral'
  'eastus'
  'eastus2'
  'southcentralus'
  'southeastasia'
  'westeurope'
]
var keyVaultPrivateEndpointName = '${keyVault001.name}-private-endpoint'

// Resources
resource purview001 'Microsoft.Purview/accounts@2020-12-01-preview' = {
  name: '${prefix}-purview001'
  location: contains(purviewRegions, location) ? location : 'westeurope'
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Standard'
    capacity: 4
  }
  properties: {
    cloudConnectors: {}
    friendlyName: '${prefix}-purview001'
    managedResourceGroupName: '${prefix}-purview001'
    publicNetworkAccess: 'Disabled'
  }
}

resource purview001PrivateEndpointPortal 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: purviewPrivateEndpointNamePortal
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: purviewPrivateEndpointNamePortal
        properties: {
          groupIds: [
            'portal'
          ]
          privateLinkServiceId: purview001.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource purview001PrivateEndpointPortalARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${purview001PrivateEndpointPortal.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${purview001PrivateEndpointPortal.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdPurview
        }
      }
    ]
  }
}

resource purview001PrivateEndpointAccount 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: purviewPrivateEndpointNameAccount
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: purviewPrivateEndpointNameAccount
        properties: {
          groupIds: [
            'account'
          ]
          privateLinkServiceId: purview001.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource purview001PrivateEndpointAccountARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${purview001PrivateEndpointAccount.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${purview001PrivateEndpointAccount.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdPurview
        }
      }
    ]
  }
}

resource purview001PrivateEndpointBlob 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: purviewPrivateEndpointNameBlob
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: purviewPrivateEndpointNameBlob
        properties: {
          groupIds: [
            'blob'
          ]
          privateLinkServiceId: purview001.properties.managedResources.storageAccount
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource purview001PrivateEndpointBlobARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${purview001PrivateEndpointBlob.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${purview001PrivateEndpointBlob.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdBlob
        }
      }
    ]
  }
}

resource purview001PrivateEndpointQueue 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: purviewPrivateEndpointNameQueue
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: purviewPrivateEndpointNameQueue
        properties: {
          groupIds: [
            'queue'
          ]
          privateLinkServiceId: purview001.properties.managedResources.storageAccount
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource purview001PrivateEndpointQueueARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${purview001PrivateEndpointQueue.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${purview001PrivateEndpointQueue.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdQueue
        }
      }
    ]
  }
}

resource purview001PrivateEndpointNamespace 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: purviewPrivateEndpointNameNamespace
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: purviewPrivateEndpointNameNamespace
        properties: {
          groupIds: [
            'namespace'
          ]
          privateLinkServiceId: purview001.properties.managedResources.eventHubNamespace
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource purview001PrivateEndpointNamespaceARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${purview001PrivateEndpointNamespace.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${purview001PrivateEndpointNamespace.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdNamespace
        }
      }
    ]
  }
}

resource keyVault001 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: '${prefix}-keyvault001'
  location: location
  tags: tags
  properties: {
    accessPolicies: []
    createMode: 'default'
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enablePurgeProtection: true
    enableRbacAuthorization: true
    enableSoftDelete: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    sku: {
      family: 'A'
      name: 'standard'
    }
    softDeleteRetentionInDays: 7
    tenantId: subscription().tenantId
  }
}

resource keyVault001PrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: keyVaultPrivateEndpointName
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: keyVaultPrivateEndpointName
        properties: {
          groupIds: [
            'vault'
          ]
          privateLinkServiceId: keyVault001.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource keyVault001PrivateEndpointARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${keyVault001PrivateEndpoint.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${keyVault001PrivateEndpoint.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdVault
        }
      }
    ]
  }
}

resource purviewKeyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: '${guid(uniqueString(concat(resourceGroup().id, purview001.id, keyVault001.id)))}'
  properties: {
    principalId: purview001.identity.principalId
    principalType: 'MSI'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
  }
}

// Outputs

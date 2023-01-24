// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create an EventHub Namespace.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param subnetId string
param eventhubnamespaceName string
@minValue(1)
@maxValue(20)
param eventhubnamespaceMinThroughput int
@minValue(1)
@maxValue(20)
param eventhubnamespaceMaxThroughput int
param eventhubNames array = []
param privateDnsZoneIdEventhubNamespace string = ''

// Variables
var eventhubNamespacePrivateEndpointName = '${eventhubNamespace.name}-private-endpoint'

// Resources
resource eventhubNamespace 'Microsoft.EventHub/namespaces@2022-01-01-preview' = {
  name: eventhubnamespaceName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: eventhubnamespaceMinThroughput
  }
  properties: {
    disableLocalAuth: true
    isAutoInflateEnabled: true
    kafkaEnabled: true
    maximumThroughputUnits: eventhubnamespaceMaxThroughput
    zoneRedundant: true
  }
}

resource eventhubNamespaceNetworkRuleSets 'Microsoft.EventHub/namespaces/networkRuleSets@2022-01-01-preview' = {
  name: 'default'
  parent: eventhubNamespace
  properties: {
    defaultAction: 'Deny'
    ipRules: []
    virtualNetworkRules: []
    publicNetworkAccess: 'Enabled'
    trustedServiceAccessEnabled: true
  }
}

resource eventhubs 'Microsoft.EventHub/namespaces/eventhubs@2022-01-01-preview' = [for item in eventhubNames: {
  parent: eventhubNamespace
  name: item
  properties: {
    captureDescription: {
      enabled: false
      destination: {
        name: 'default'
        properties: {
          archiveNameFormat: ''
          blobContainer: ''
          storageAccountResourceId: ''
        }
      }
      encoding: 'Avro'
      intervalInSeconds: 900
      sizeLimitInBytes: 10485760
      skipEmptyArchives: true
    }
    messageRetentionInDays: 3
    partitionCount: 1
    status: 'Active'
  }
}]

resource eventhubNamespacePrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: eventhubNamespacePrivateEndpointName
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: eventhubNamespacePrivateEndpointName
        properties: {
          groupIds: [
            'namespace'
          ]
          privateLinkServiceId: eventhubNamespace.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource eventhubNamespacePrivateEndpointARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = if (!empty(privateDnsZoneIdEventhubNamespace)) {
  parent: eventhubNamespacePrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${eventhubNamespacePrivateEndpoint.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdEventhubNamespace
        }
      }
    ]
  }
}

// Outputs
output eventhubNamespaceId string = eventhubNamespace.id

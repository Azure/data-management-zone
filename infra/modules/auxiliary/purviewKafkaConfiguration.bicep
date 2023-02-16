// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// The module contains a template to create Purview Kafka configurations.
targetScope = 'resourceGroup'

// Parameters
param eventhubnamespaceId string
param eventhubNotificationName string
param eventhubHookName string
param purviewId string

// Variables
var eventhubnamespaceSubscriptionId = length(split(eventhubnamespaceId, '/')) >= 9 ? split(eventhubnamespaceId, '/')[2] : subscription().subscriptionId
var eventhubnamespaceResourceGroupName = length(split(eventhubnamespaceId, '/')) >= 9 ? split(eventhubnamespaceId, '/')[4] : resourceGroup().name
var eventhubnamespaceName = length(split(eventhubnamespaceId, '/')) >= 9 ? last(split(eventhubnamespaceId, '/')) : 'incorrectSegmentLength'
var purviewName = length(split(purviewId, '/')) >= 9 ? last(split(purviewId, '/')) : 'incorrectSegmentLength'

// Resources
resource eventhubnamespace 'Microsoft.EventHub/namespaces@2022-01-01-preview' existing = {
  name: eventhubnamespaceName
  scope: resourceGroup(eventhubnamespaceSubscriptionId, eventhubnamespaceResourceGroupName)
}

resource eventhubNotification 'Microsoft.EventHub/namespaces/eventhubs@2022-01-01-preview' existing = {
  parent: eventhubnamespace
  name: eventhubNotificationName
}

resource eventhubHook 'Microsoft.EventHub/namespaces/eventhubs@2022-01-01-preview' existing = {
  parent: eventhubnamespace
  name: eventhubHookName
}

resource purview 'Microsoft.Purview/accounts@2021-07-01' existing = {
  name: purviewName
}

resource purviewKafkaConfigurationNotification 'Microsoft.Purview/accounts/kafkaConfigurations@2021-12-01' = {
  parent: purview
  name: 'notification'
  properties: {
    credentials: {
      type: 'SystemAssigned'
    }
    eventHubResourceId: eventhubNotification.id
    eventHubType: 'Notification'
    eventStreamingState: 'Enabled'
    eventStreamingType: 'Azure'
  }
}

resource purviewKafkaConfigurationHook 'Microsoft.Purview/accounts/kafkaConfigurations@2021-12-01' = {
  parent: purview
  name: 'hook'
  properties: {
    credentials: {
      type: 'SystemAssigned'
    }
    eventHubResourceId: eventhubHook.id
    eventHubType: 'Hook'
    eventStreamingState: 'Enabled'
    eventStreamingType: 'Azure'
    consumerGroup: '$Default'
  }
}

// Outputs

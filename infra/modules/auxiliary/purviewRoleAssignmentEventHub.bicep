// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// The module contains a template to create a role assignment from Purview to an EventHub.
targetScope = 'resourceGroup'

// Parameters
param eventhubnamespaceId string
param eventhubName string
param purviewId string
@allowed([
  'AzureEventHubsDataReceiver'
  'AzureEventHubsDataSender'
])
param role string

// Variables
var eventhubnamespaceName = length(split(eventhubnamespaceId, '/')) >= 9 ? last(split(eventhubnamespaceId, '/')) : 'incorrectSegmentLength'
var purviewSubscriptionId = length(split(purviewId, '/')) >= 9 ? split(purviewId, '/')[2] : subscription().subscriptionId
var purviewResourceGroupName = length(split(purviewId, '/')) >= 9 ? split(purviewId, '/')[4] : resourceGroup().name
var purviewName = length(split(purviewId, '/')) >= 9 ? last(split(purviewId, '/')) : 'incorrectSegmentLength'
var roles = {
  AzureEventHubsDataReceiver: 'a638d3c7-ab3a-418d-83e6-5f17a39d4fde'
  AzureEventHubsDataSender: '2b629674-e913-4c01-ae53-ef4638d8f975'
}

// Resources
resource eventhubnamespace 'Microsoft.EventHub/namespaces@2022-01-01-preview' existing = {
  name: eventhubnamespaceName
}

resource eventhub 'Microsoft.EventHub/namespaces/eventhubs@2022-01-01-preview' existing = {
  parent: eventhubnamespace
  name: eventhubName
}

resource purview 'Microsoft.Purview/accounts@2020-12-01-preview' existing = {
  name: purviewName
  scope: resourceGroup(purviewSubscriptionId, purviewResourceGroupName)
}

resource purviewRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(uniqueString(eventhub.id, purview.id))
  scope: eventhub
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roles[role])
    principalId: purview.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used as a module from the main.bicep template. 
// The module contains a template to create the governance services.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
param privateDnsZoneIdPurview string = ''
param privateDnsZoneIdPurviewPortal string = ''
param privateDnsZoneIdStorageBlob string = ''
param privateDnsZoneIdStorageQueue string = ''
param privateDnsZoneIdEventhubNamespace string = ''
param privateDnsZoneIdKeyVault string = ''

// Variables
var purview001Name = '${prefix}-purview001'
var keyvault001Name = '${prefix}-vault001'
var eventhubnamespace001Name = '${prefix}-eventhub001'
var eventhubNotificationName = 'notification'
var eventhubHookName = 'hook'
var eventhubnamespace001EventhubNames = [
  eventhubNotificationName
  eventhubHookName
]

// Resources
module purview001 'services/purview.bicep' = {
  name: 'purview001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    purviewName: purview001Name
    privateDnsZoneIdEventhubNamespace: eventhubnamespace001.outputs.eventhubNamespaceId
    privateDnsZoneIdPurview: privateDnsZoneIdPurview
    privateDnsZoneIdPurviewPortal: privateDnsZoneIdPurviewPortal
    privateDnsZoneIdStorageBlob: privateDnsZoneIdStorageBlob
    privateDnsZoneIdStorageQueue: privateDnsZoneIdStorageQueue
  }
}

module eventhubnamespace001 'services/eventhubnamespace.bicep' = {
  name: 'eventhubnamespace001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    eventhubnamespaceName: eventhubnamespace001Name
    eventhubNames: eventhubnamespace001EventhubNames
    eventhubnamespaceMinThroughput: 1
    eventhubnamespaceMaxThroughput: 1
    privateDnsZoneIdEventhubNamespace: privateDnsZoneIdEventhubNamespace
  }
}

module keyVault001 'services/keyvault.bicep' = {
  name: 'keyVault001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    keyvaultName: keyvault001Name
    privateDnsZoneIdKeyVault: privateDnsZoneIdKeyVault
  }
}

module purviewKafkaConfiguration 'auxiliary/purviewKafkaConfiguration.bicep' = {
  name: 'purviewKafkaConfiguration'
  dependsOn: [
    purviewRoleAssignmentEventhubHook
    purviewRoleAssignmentEventhubNotification
  ]
  params: {
    purviewId: purview001.outputs.purviewId
    eventhubnamespaceId: eventhubnamespace001.outputs.eventhubNamespaceId
    eventhubHookName: eventhubHookName
    eventhubNotificationName: eventhubNotificationName
  }
}

module purviewRoleAssignmentKeyVault 'auxiliary/purviewRoleAssignmentKeyVault.bicep' = {
  name: 'purviewRoleAssignmentKeyVault'
  scope: resourceGroup()
  params: {
    purviewId: purview001.outputs.purviewId
    keyVaultId: keyVault001.outputs.keyvaultId
    role: 'KeyVaultSecretsUser'
  }
}

module purviewRoleAssignmentEventhubNotification 'auxiliary/purviewRoleAssignmentEventHub.bicep' = {
  name: 'purviewRoleAssignmentEventhubNotification'
  scope: resourceGroup()
  params: {
    purviewId: purview001.outputs.purviewId
    eventhubnamespaceId: eventhubnamespace001.outputs.eventhubNamespaceId
    eventhubName: eventhubNotificationName
    role: 'AzureEventHubsDataSender'
  }
}

module purviewRoleAssignmentEventhubHook 'auxiliary/purviewRoleAssignmentEventHub.bicep' = {
  name: 'purviewRoleAssignmentEventhubHook'
  scope: resourceGroup()
  params: {
    purviewId: purview001.outputs.purviewId
    eventhubnamespaceId: eventhubnamespace001.outputs.eventhubNamespaceId
    eventhubName: eventhubHookName
    role: 'AzureEventHubsDataReceiver'
  }
}

// Outputs
output purviewId string = purview001.outputs.purviewId
output purviewManagedStorageId string = purview001.outputs.purviewManagedStorageId
output purviewManagedEventHubId string = eventhubnamespace001.outputs.eventhubNamespaceId

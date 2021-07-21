// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a public storage account.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param artifactstorageName string

// Variables
var artifactstorageNameCleaned = replace(artifactstorageName, '-', '')

// Resources
resource artifactstorage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: artifactstorageNameCleaned
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    encryption: {
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: false
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
        queue: {
          enabled: true
          keyType: 'Service'
        }
        table: {
          enabled: true
          keyType: 'Service'
        }
      }
    }
    isHnsEnabled: false
    isNfsV3Enabled: false
    largeFileSharesState: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
      resourceAccessRules: []
    }
    routingPreference: {
      routingChoice: 'MicrosoftRouting'
      publishInternetEndpoints: false
      publishMicrosoftEndpoints: false
    }
    supportsHttpsTrafficOnly: true
  }
}

resource artifactstorageScriptsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' = {
  name: '${artifactstorage.name}/default/scripts'
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}

// Outputs
output storageAccountId string = artifactstorage.id
output storageAccountContainerName string = artifactstorageScriptsContainer.name

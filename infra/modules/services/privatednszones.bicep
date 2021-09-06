// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create Private DNS Zones.
targetScope = 'resourceGroup'

// Parameters
param vnetId string
param tags object

// Variables
var vnetName = length(split(vnetId, '/')) >= 9 ? last(split(vnetId, '/')) : 'incorrectSegmentLength'
var privateDnsZoneNames = [
  'privatelink.afs.azure.net'
  'privatelink.analysis.windows.net'
  'privatelink.api.azureml.ms'
  'privatelink.azure-automation.net'
  'privatelink.azure-devices.net'
  'privatelink.adf.azure.com'
  'privatelink.azurecr.io'
  'privatelink.azuredatabricks.net'
  'privatelink.azuresynapse.net'
  'privatelink.azurewebsites.net'
  'privatelink.blob.${environment().suffixes.storage}'
  'privatelink.cassandra.cosmos.azure.com'
  'privatelink.cognitiveservices.azure.com'
  'privatelink${environment().suffixes.sqlServerHostname}'
  'privatelink.datafactory.azure.net'
  'privatelink.dev.azuresynapse.net'
  'privatelink.dfs.${environment().suffixes.storage}'
  'privatelink.documents.azure.com'
  'privatelink.eventgrid.azure.net'
  'privatelink.file.${environment().suffixes.storage}'
  'privatelink.gremlin.cosmos.azure.com'
  'privatelink.mariadb.database.azure.com'
  'privatelink.mongo.cosmos.azure.com'
  'privatelink.mysql.database.azure.com'
  'privatelink.notebooks.azure.net'
  'privatelink.pbidedicated.windows.net'
  'privatelink.postgres.database.azure.com'
  'privatelink.purview.azure.com'
  'privatelink.queue.${environment().suffixes.storage}'
  'privatelink.redis.cache.windows.net'
  'privatelink.search.windows.net'
  'privatelink.service.signalr.net'
  'privatelink.servicebus.windows.net'
  'privatelink.sql.azuresynapse.net'
  'privatelink.table.${environment().suffixes.storage}'
  'privatelink.table.cosmos.azure.com'
  'privatelink.prod.powerquery.microsoft.com'
  'privatelink.vaultcore.azure.net'
  'privatelink.web.${environment().suffixes.storage}'
  'privatelink.northeurope.azmk8s.io'
  'privatelink.westeurope.azmk8s.io'
  'privatelink.northeurope.batch.azure.com'
  'privatelink.westeurope.batch.azure.com'
  'northeurope.privatelink.redisenterprise.cache.azure.net'
  'westeurope.privatelink.redisenterprise.cache.azure.net'
]

// Resources
resource privateDnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' = [for item in privateDnsZoneNames: {
  name: item
  location: 'global'
  tags: tags
  properties: {}
}]

resource virtualNetworkLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for item in privateDnsZoneNames: {
  name: '${item}/${vnetName}'
  location: 'global'
  dependsOn: [
    privateDnsZones
  ]
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}]

// Outputs
output privateDnsZoneIdFileSync string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.afs.azure.net'
output privateDnsZoneIdMachineLearningApi string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.api.azureml.ms'
output privateDnsZoneIdMachineLearningNotebooks string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.notebooks.azure.net'
output privateDnsZoneIdAutomation string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.azure-automation.net'
output privateDnsZoneIdIothub string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.azure-devices.net'
output privateDnsZoneIdDataFactory string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.datafactory.azure.net'
output privateDnsZoneIdDataFactoryPortal string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.adf.azure.com'
output privateDnsZoneIdAppService string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.azurewebsites.net'
output privateDnsZoneIdCosmosdbCassandra string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.cassandra.cosmos.azure.com'
output privateDnsZoneIdCosmosdbSql string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.documents.azure.com'
output privateDnsZoneIdCosmosdbGremlin string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.gremlin.cosmos.azure.com'
output privateDnsZoneIdCosmosdbMongo string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.mongo.cosmos.azure.com'
output privateDnsZoneIdCosmosdbTable string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.table.cosmos.azure.com'
output privateDnsZoneIdCognitiveService string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.cognitiveservices.azure.com'
output privateDnsZoneIdSqlServer string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink${environment().suffixes.sqlServerHostname}'
output privateDnsZoneIdMySqlServer string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.mysql.database.azure.com'
output privateDnsZoneIdMariaDb string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.mariadb.database.azure.com'
output privateDnsZoneIdPostgreSql string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.postgres.database.azure.com'
output privateDnsZoneIdRedis string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.redis.cache.windows.net'
output privateDnsZoneIdSearch string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.search.windows.net'
output privateDnsZoneIdSignalr string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.service.signalr.net'
output privateDnsZoneIdEventGrid string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.eventgrid.azure.net'
output privateDnsZoneIdPurview string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.purview.azure.com'
output privateDnsZoneIdDfs string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.dfs.${environment().suffixes.storage}'
output privateDnsZoneIdBlob string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.blob.${environment().suffixes.storage}'
output privateDnsZoneIdFile string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.file.${environment().suffixes.storage}'
output privateDnsZoneIdQueue string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.queue.${environment().suffixes.storage}'
output privateDnsZoneIdWeb string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.web.${environment().suffixes.storage}'
output privateDnsZoneIdNamespace string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.servicebus.windows.net'
output privateDnsZoneIdKeyVault string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net'
output privateDnsZoneIdContainerRegistry string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.azurecr.io'
output privateDnsZoneIdSynapse string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.azuresynapse.net'
output privateDnsZoneIdSynapseDev string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.dev.azuresynapse.net'
output privateDnsZoneIdSynapseSql string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.sql.azuresynapse.net'
output privateDnsZoneIdAnalysis string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.analysis.windows.net'
output privateDnsZoneIdPbiDedicated string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.pbidedicated.windows.net'
output privateDnsZoneIdPowerQuery string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.prod.powerquery.microsoft.com'

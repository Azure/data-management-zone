// This template is used to create Private DNS Zones.
targetScope = 'resourceGroup'

// Parameters
param vnetId string
param tags object

// Variables
var vnetName = last(split(vnetId, '/'))
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
output privateDnsZoneIdPurview string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.purview.azure.com'
output privateDnsZoneIdBlob string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.blob.${environment().suffixes.storage}'
output privateDnsZoneIdQueue string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.queue.${environment().suffixes.storage}'
output privateDnsZoneIdNamespace string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.servicebus.windows.net'
output privateDnsZoneIdKeyVault string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net'
output privateDnsZoneIdContainerRegistry string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.azurecr.io'
output privateDnsZoneIdSynapse string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.azuresynapse.net'
output privateDnsZoneIdAnalysis string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.analysis.windows.net'
output privateDnsZoneIdPbiDedicated string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.pbidedicated.windows.net'
output privateDnsZoneIdPowerQuery string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.prod.powerquery.microsoft.com'

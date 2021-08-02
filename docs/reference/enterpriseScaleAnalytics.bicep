// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

targetScope = 'subscription'

// General parameters
@allowed([
  'dev'
  'tst'
  'prd'
])
@description('Specifies the environment.')
param environment string = 'dev'
@description('Specifies the tags that you want to apply to all resources.')
param tags object

// Data Management Parameters
@description('Specifies the subscription ID where your Data Management Zone will be deployed.')
param dataManagementZoneSubscriptionId string
@description('Specifies the prefix of your Data Management Zone.')
param dataManagementZonePrefix string
@description('Specifies the location of your Data Management Zone.')
param dataManagementZoneLocation string

// Data Landing Zone Parameters
@description('Specifies the administrator password of the Synapse workspace and the virtual machine scale sets.')
param administratorPassword string
@description('Specifies the details of each Data Landing Zone in an array of objects.')
param dataLandingZoneDetails array
@description('Specifies the prefix of Data Landing Zones.')
param dataLandingZonePrefix string

// Variables
var dataManagementZoneTemplateLink = 'https://raw.githubusercontent.com/Azure/data-management-zone/main/infra/main.json'
var dataLandingZoneTemplateLink = 'https://raw.githubusercontent.com/Azure/data-landing-zone/main/infra/main.json'

// Resources
resource dataManagementZoneDeployment 'Microsoft.Resources/deployments@2021-04-01' = {
  name: 'dataManagementZoneDeployment-${deployment().location}'
  location: dataManagementZoneLocation
  subscriptionId: dataManagementZoneSubscriptionId
  properties: {
    mode: 'Incremental'
    templateLink: {
      contentVersion: '1.0.0.0'
      uri: dataManagementZoneTemplateLink
    }
    parameters: {
      location: {
        value: dataManagementZoneLocation
      }
      environment: {
        value: environment
      }
      prefix: {
        value: dataManagementZonePrefix
      }
      tags: {
        value: tags
      }
      vnetAddressPrefix: {
        value: '10.0.0.0/16'
      }
      azureFirewallSubnetAddressPrefix: {
        value: '10.0.0.0/24'
      }
      servicesSubnetAddressPrefix: {
        value: '10.0.1.0/24'
      }
      enableDnsAndFirewallDeployment: {
        value: true
      }
      firewallPrivateIp: {
        value: '10.0.0.4'
      }
      dnsServerAdresses: {
        value: [
          '10.0.0.4'
        ]
      }
      firewallPolicyId: {
        value: ''
      }
      privateDnsZoneIdBlob: {
        value: ''
      }
      privateDnsZoneIdContainerRegistry: {
        value: ''
      }
      privateDnsZoneIdKeyVault: {
        value: ''
      }
      privateDnsZoneIdNamespace: {
        value: ''
      }
      privateDnsZoneIdPurview: {
        value: ''
      }
      privateDnsZoneIdQueue: {
        value: ''
      }
      privateDnsZoneIdSynapse: {
        value: ''
      }
    }
  }
}

resource dataLandingZoneDeployment 'Microsoft.Resources/deployments@2021-04-01' = [for (item, index) in dataLandingZoneDetails: {
  name: 'dataLandingZoneDeployment-${index}-${deployment().location}'
  location: item.location
  subscriptionId: item.subscription
  properties: {
    mode: 'Incremental'
    templateLink: {
      contentVersion: '1.0.0.0'
      uri: dataLandingZoneTemplateLink
    }
    parameters: {
      location: {
        value: item.location
      }
      environment: {
        value: environment
      }
      prefix: {
        value: '${dataLandingZonePrefix}${padLeft(index + 1, 3, '0')}'
      }
      tags: {
        value: tags
      }
      vnetAddressPrefix: {
        value: '10.${index + 1}.0.0/16'
      }
      servicesSubnetAddressPrefix: {
        value: '10.${index + 1}.0.0/24'
      }
      databricksIntegrationPublicSubnetAddressPrefix: {
        value: '10.${index + 1}.1.0/24'
      }
      databricksIntegrationPrivateSubnetAddressPrefix: {
        value: '10.${index + 1}.2.0/24'
      }
      databricksProductPublicSubnetAddressPrefix: {
        value: '10.${index + 1}.3.0/24'
      }
      databricksProductPrivateSubnetAddressPrefix: {
        value: '10.${index + 1}.4.0/24'
      }
      powerBiGatewaySubnetAddressPrefix: {
        value: '10.${index + 1}.5.0/24'
      }
      dataIntegration001SubnetAddressPrefix: {
        value: '10.${index + 1}.6.0/24'
      }
      dataIntegration002SubnetAddressPrefix: {
        value: '10.${index + 1}.7.0/24'
      }
      dataProduct001SubnetAddressPrefix: {
        value: '10.${index + 1}.8.0/24'
      }
      dataProduct002SubnetAddressPrefix: {
        value: '10.${index + 1}.9.0/24'
      }
      dataManagementZoneVnetId: {
        value: reference(dataManagementZoneDeployment.name).outputs.vnetId.value
      }
      firewallPrivateIp: {
        value: reference(dataManagementZoneDeployment.name).outputs.firewallPrivateIp.value
      }
      dnsServerAdresses: {
        value: [
          reference(dataManagementZoneDeployment.name).outputs.firewallPrivateIp.value
        ]
      }
      administratorPassword: {
        value: administratorPassword
      }
      purviewId: {
        value: reference(dataManagementZoneDeployment.name).outputs.purviewId.value
      }
      purviewSelfHostedIntegrationRuntimeAuthKey: {
        value: ''
      }
      portalDeployment: {
        value: true
      }
      deploySelfHostedIntegrationRuntimes: {
        value: true
      }
      privateDnsZoneIdKeyVault: {
        value: reference(dataManagementZoneDeployment.name).outputs.privateDnsZoneIdKeyVault.value
      }
      privateDnsZoneIdDataFactory: {
        value: reference(dataManagementZoneDeployment.name).outputs.privateDnsZoneIdDataFactory.value
      }
      privateDnsZoneIdDataFactoryPortal: {
        value: reference(dataManagementZoneDeployment.name).outputs.privateDnsZoneIdDataFactoryPortal.value
      }
      privateDnsZoneIdBlob: {
        value: reference(dataManagementZoneDeployment.name).outputs.privateDnsZoneIdBlob.value
      }
      privateDnsZoneIdDfs: {
        value: reference(dataManagementZoneDeployment.name).outputs.privateDnsZoneIdDfs.value
      }
      privateDnsZoneIdSqlServer: {
        value: reference(dataManagementZoneDeployment.name).outputs.privateDnsZoneIdSqlServer.value
      }
      privateDnsZoneIdMySqlServer: {
        value: reference(dataManagementZoneDeployment.name).outputs.privateDnsZoneIdMySqlServer.value
      }
      privateDnsZoneIdEventhubNamespace: {
        value: reference(dataManagementZoneDeployment.name).outputs.privateDnsZoneIdNamespace.value
      }
      privateDnsZoneIdSynapseDev: {
        value: reference(dataManagementZoneDeployment.name).outputs.privateDnsZoneIdSynapseDev.value
      }
      privateDnsZoneIdSynapseSql: {
        value: reference(dataManagementZoneDeployment.name).outputs.privateDnsZoneIdSynapseSql.value
      }
    }
  }
}]

module vnetPeeringDeployment 'modules/vnetPeeringOrchestration.bicep' = [for index1 in range(0, length(dataLandingZoneDetails)): {
  name: 'vnetPeeringDeployment-${index1}-${deployment().location}'
  scope: subscription()
  params: {
    sourceVnetId: reference(dataLandingZoneDeployment[index1].name).outputs.vnetId.value
    destinationVnetIds: [for index2 in range(0, length(dataLandingZoneDetails)): reference(dataLandingZoneDeployment[index2].name).outputs.vnetId.value]
  }
}]

// Outputs

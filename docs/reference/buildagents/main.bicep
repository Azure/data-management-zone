// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

targetScope = 'resourceGroup'

// General parameters
@description('Specifies the location of your Data Landing Zone or Data Management Zone.')
param location string
@allowed([
  'dev'
  'tst'
  'prd'
])
@description('Specifies the environment of your Data Landing Zone or Data Management Zone.')
param environment string = 'dev'
@minLength(2)
@maxLength(10)
@description('Specifies the prefix of your Data Landing Zone or Data Management Zone.')
param prefix string
@description('Specifies the tags that you want to apply to all resources.')
param tags object = {}

// Network parameters
@description('Specifies the resource ID of the subnet to which all services will connect.')
param subnetId string

// Virtual Machine parameters
@description('Specifies the SKU of the virtual machine that gets created.')
param virtualMachineSku string = 'Standard_F8s_v2'
@description('Specifies the administrator username of the virtual machine.')
param administratorUsername string = 'VmMainUser'
@secure()
@description('Specifies the administrator password of the virtual machine.')
param administratorPassword string

// Variables
var name = toLower('${prefix}-${environment}')
var tagsDefault = {
  Owner: 'Data Management and Analytics Scenario'
  Project: 'Data Management and Analytics Scenario'
  Environment: environment
  Toolkit: 'bicep'
  Name: name
}
var tagsJoined = union(tagsDefault, tags)
var selfHostedAgentDevOps001Name = '${name}-agent001'

// Resources
module selfHostedAgentDevOps001 'modules/services/selfHostedAgentAzureDevOps.bicep' = {
  name: 'selfHostedAgentDevOps001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tagsJoined
    administratorUsername: administratorUsername
    administratorPassword: administratorPassword
    subnetId: subnetId
    vmssName: selfHostedAgentDevOps001Name
    vmssSkuName: virtualMachineSku
    vmssSkuTier: 'Standard'
    vmssSkuCapacity: 1
  }
}

// Outputs

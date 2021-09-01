// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

targetScope = 'subscription'

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
@description('Specifies the resource Id of the vnet in your Data Landing Zone or Data Management Zone.')
param vnetId string
@description('Specifies the resource Id of the default network security group of your Data Landing Zone or Data Management Zone.')
param defaultNsgId string
@description('Specifies the resource Id of the default route table of your Data Landing Zone or Data Management Zone.')
param defaultRouteTableId string
@description('Specifies the address space of the subnet that is used for Azure Bastion.')
param bastionSubnetAddressPrefix string = '10.1.10.0/24'
@description('Specifies the address space of the subnet that is used for Jumboxes.')
param jumpboxSubnetAddressPrefix string = '10.1.11.0/24'

// Virtual Machine parameters
@description('Specifies the SKU of the virtual machine that gets created.')
param virtualMachineSku string = 'Standard_DS2_v2'
@description('Specifies the administrator username of the virtual machine.')
param administratorUsername string = 'VmMainUser'
@secure()
@description('Specifies the administrator password of the virtual machine.')
param administratorPassword string

// Variables
var name = toLower('${prefix}-${environment}')
var tagsDefault = {
  Owner: 'Enterprise Scale Analytics'
  Project: 'Enterprise Scale Analytics'
  Environment: environment
  Toolkit: 'bicep'
  Name: name
}
var tagsJoined = union(tagsDefault, tags)
var vnetSubscriptionId = length(split(vnetId, '/')) >= 9 ? split(vnetId, '/')[2] : subscription().id
var vnetResourceGroupName = length(split(vnetId, '/')) >= 9 ? split(vnetId, '/')[4] : 'incorrectSegmentLength'
var vnetName = length(split(vnetId, '/')) >= 9 ? last(split(vnetId, '/')) : 'incorrectSegmentLength'

// Resources
module networkServices 'modules/network.bicep' = {
  name: 'networkServices'
  scope: resourceGroup(vnetSubscriptionId, vnetResourceGroupName)
  params: {
    location: location
    prefix: name
    tags: tagsJoined
    vnetName: vnetName
    bastionSubnetAddressPrefix: bastionSubnetAddressPrefix
    jumpboxSubnetAddressPrefix: jumpboxSubnetAddressPrefix
    defaultNsgId: defaultNsgId
    defaultRouteTableId: defaultRouteTableId
  }
}

resource bastionResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-bastion'
  location: location
  tags: tagsJoined
  properties: {}
}

module bastionServices 'modules/bastion.bicep' = {
  name: 'bastionServices'
  scope: bastionResourceGroup
  params: {
    location: location
    prefix: name
    tags: tagsJoined
    virtualMachineSku: virtualMachineSku
    bastionSubnetId: networkServices.outputs.bastionSubnetId
    jumpboxSubnetId: networkServices.outputs.jumpboxSubnetId
    administratorUsername: administratorUsername
    administratorPassword: administratorPassword
  }
}

// Outputs

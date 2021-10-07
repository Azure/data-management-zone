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
  Owner: 'Enterprise Scale Analytics'
  Project: 'Enterprise Scale Analytics'
  Environment: environment
  Toolkit: 'bicep'
  Name: name
}
var tagsJoined = union(tagsDefault, tags)

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

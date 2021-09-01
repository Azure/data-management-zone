// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used as a module from the main.bicep template. 
// The module contains a template to create storage resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param bastionSubnetId string
param jumpboxSubnetId string
param virtualMachineSku string = 'Standard_DS2_v2'
param administratorUsername string = 'VmMainUser'
@secure()
param administratorPassword string

// Variables
var bastion001Name = '${prefix}-bastion001'
var virtualMachine001Name = '${prefix}-vm001'

// Resources
module bastion001 'services/bastion.bicep' = {
  name: 'bastion001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    bastionName: bastion001Name
    subnetId: bastionSubnetId
  }
}

module virtualMachine001 'services/virtualmachine.bicep' = {
  name: 'virtualMachine001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: jumpboxSubnetId
    virtualmachineName: virtualMachine001Name
    virtualMachineSku: virtualMachineSku
    administratorUsername: administratorUsername
    administratorPassword: administratorPassword
  }
}

// Outputs

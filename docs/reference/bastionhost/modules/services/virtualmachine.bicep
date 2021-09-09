// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used as a module from the main.bicep template.
// The module contains a template to deploy a virtual machine.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param virtualmachineName string
param virtualMachineSku string = 'Standard_DS2_v2'
param administratorUsername string = 'VmMainUser'
@secure()
param administratorPassword string
param subnetId string

// Variables
var nicName = '${virtualmachineName}-nic'
var diskName = '${virtualmachineName}-disk'

// Resources
resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: nicName
  location: location
  tags: tags
  properties: {
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    ipConfigurations: [
      {
        name: 'ipConfig'
        properties: {
          primary: true
          privateIPAddressVersion: 'IPv4'
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    nicType: 'Standard'
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-04-01' = {
  name: virtualmachineName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSku
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    osProfile: {
      adminUsername: administratorUsername
      adminPassword: administratorPassword
      computerName: take(virtualmachineName, 15)
      allowExtensionOperations: true
      windowsConfiguration: {
        enableAutomaticUpdates: true
      }
    }
    priority: 'Regular'
    storageProfile: {
      imageReference: {
        offer: 'WindowsServer'
        publisher: 'MicrosoftWindowsServer'
        sku: '2022-datacenter'
        version: 'latest'
      }
      osDisk: {
        name: diskName
        caching: 'ReadWrite'
        createOption: 'FromImage'
        osType: 'Windows'
        writeAcceleratorEnabled: false
      }
    }
  }
}

// Outputs

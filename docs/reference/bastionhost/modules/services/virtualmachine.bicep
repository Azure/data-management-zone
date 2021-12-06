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
@allowed([
  'Windows11'
  'WindowsServer2022'
])
param virtualMachineImage string = 'Windows11'
param administratorUsername string = 'VmMainUser'
@secure()
param administratorPassword string
param subnetId string

// Variables
var nicName = '${virtualmachineName}-nic'
var diskName = '${virtualmachineName}-disk'
var imageReferenceWindows11 = {
  publisher: 'microsoftwindowsdesktop'
  offer: 'windows-11'
  sku: 'win11-21h2-ent'
  version: 'latest'
}
var imageReferenceWindowsServer2022 = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2022-datacenter'
  version: 'latest'
}

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
      imageReference: virtualMachineImage == 'Windows11' ? imageReferenceWindows11 : imageReferenceWindowsServer2022
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

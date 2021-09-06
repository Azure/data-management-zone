// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used as a module from the main.bicep template. 
// The module contains a template to create the dns forwarder 
// services if customer want to rely on VMs instead of Azure Firewall.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
param vmssSkuName string = 'Standard_A1_v2'
param vmssSkuTier string = 'Standard'
param vmssSkuCapacity int = 2
param vmssAdmininstratorUsername string = 'VmssMainUser'
@secure()
param vmssAdministratorPublicSshKey string

// Variables
var artifactstorage001Name = '${prefix}-artfct001'
var dnsForwarder001Name = '${prefix}dnsproxy001'

// Resources
module artifactstorage001 'services/artifactstorage.bicep' = {
  name: 'artifactstorage001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    artifactstorageName: artifactstorage001Name
  }
}

module dnsforwarder001 'services/dnsforwarder.bicep' = {
  name: 'dnsforwarder001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    dnsForwarderName: dnsForwarder001Name
    storageAccountId: artifactstorage001.outputs.storageAccountId
    storageAccountContainerName: artifactstorage001.outputs.storageAccountContainerName
    vmssSkuName: vmssSkuName
    vmssSkuTier: vmssSkuTier
    vmssSkuCapacity: vmssSkuCapacity
    vmssAdmininstratorUsername: vmssAdmininstratorUsername
    vmssAdministratorPublicSshKey: vmssAdministratorPublicSshKey
  }
}

// Outputs

// This template is used as a module from the main.bicep template. 
// The module contains a template to create the dns forwarder 
// services if customer want to rely on VMs.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
param vmssSkuName string = 'Standard_A1_v2'
param vmssSkuTier string = 'Standard'
param vmssSkuCapacity int = 2
param vmssAdminUsername string = 'VmssMainUser'
@secure()
param vmssAdminPublicSshKey string

// Variables
var vmssName = '${prefix}dnsproxy001'

// Resources
resource artifactstorage001 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: replace('${prefix}artifactstorage001', '-', '')
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    encryption: {
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: false
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
        queue: {
          enabled: true
          keyType: 'Service'
        }
        table: {
          enabled: true
          keyType: 'Service'
        }
      }
    }
    isHnsEnabled: false
    isNfsV3Enabled: false
    largeFileSharesState: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
      resourceAccessRules: []
    }
    routingPreference: {
      routingChoice: 'MicrosoftRouting'
      publishInternetEndpoints: false
      publishMicrosoftEndpoints: false
    }
    supportsHttpsTrafficOnly: true
  }
}

resource scriptsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' = {
  name: '${artifactstorage001.name}/default/scripts'
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}

resource loadBalancer001 'Microsoft.Network/loadBalancers@2020-11-01' = {
  name: '${vmssName}-lb'
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Global'
  }
  properties: {
    backendAddressPools: [
      {
        name: '${vmssName}-backendpool'
      }
    ]
    frontendIPConfigurations: [
      {
        name: '${vmssName}-ipfrontend'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    inboundNatPools: [
      {
        name: '${vmssName}-natpool'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', '${vmssName}-lb', '${vmssName}-ipfrontend')
          }
          protocol: 'Tcp'
          frontendPortRangeStart: 50000
          frontendPortRangeEnd: 50099
          backendPort: 22
          idleTimeoutInMinutes: 4
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'roundRobinLBRule'
        properties: {
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', '${vmssName}-lb', '${vmssName}-backendpool')
          }
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', '${vmssName}-lb', '${vmssName}-ipfrontend')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', '${vmssName}-lb', '${vmssName}-probe')
          }
          protocol: 'Tcp'
          backendPort: 53
          frontendPort: 53
          enableFloatingIP: false
          loadDistribution: 'Default'
        }
      }
    ]
    probes: [
      {
        name: '${vmssName}-probe'
        properties: {
          intervalInSeconds: 5
          numberOfProbes: 2
          port: 22
          protocol: 'Tcp'
        }
      }
    ]
  }
}

resource sshPublicKey 'Microsoft.Compute/sshPublicKeys@2020-12-01' = {
  name: '${vmssName}-sshKey'
  location: location
  tags: tags
  properties: {
    publicKey: vmssAdminPublicSshKey
  }
}

resource vmss001 'Microsoft.Compute/virtualMachineScaleSets@2020-12-01' = {
  name: vmssName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: vmssSkuName
    tier: vmssSkuTier
    capacity: vmssSkuCapacity
  }
  properties: {
    additionalCapabilities: {}
    automaticRepairsPolicy: {}
    doNotRunExtensionsOnOverprovisionedVMs: true
    overprovision: true
    platformFaultDomainCount: 1
    scaleInPolicy: {
      rules: [
        'Default'
      ]
    }
    orchestrationMode: 'Flexible'
    proximityPlacementGroup: {}
    singlePlacementGroup: true
    upgradePolicy: {
      mode: 'Manual'
    }
    zoneBalance: true
    virtualMachineProfile: {
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: '${vmssName}-nic'
            properties: {
              primary: true
              enableAcceleratedNetworking: false
              dnsSettings: {}
              enableIPForwarding: false
              enableFpga: false
              ipConfigurations: [
                {
                  name: '${vmssName}-ipconfig'
                  properties: {
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', '${vmssName}-lb', '${vmssName}-backendpool')
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', '${vmssName}-lb', '${vmssName}-natpool')
                      }
                    ]
                    primary: true
                    privateIPAddressVersion: 'IPv4'
                    subnet: {
                      id: subnetId
                    }
                  }
                }
              ]
              networkSecurityGroup: {}
            }
          }
        ]
      }
      osProfile: {
        computerNamePrefix: take(vmssName, 9)
        adminUsername: vmssAdminUsername
        linuxConfiguration: {
          disablePasswordAuthentication: true
          ssh: {
            publicKeys: [
              {
                keyData: sshPublicKey.properties.publicKey
                path: '/home/${vmssAdminUsername}/.ssh/authorized_keys'
              }
            ]
          }
        }
      }
      priority: 'Regular'
      storageProfile: {
        imageReference: {
          offer: 'UbuntuServer'
          publisher: 'Canonical'
          sku: '20.04-LTS'
          version: 'latest'
        }
        osDisk: {
          caching: 'ReadWrite'
          createOption: 'FromImage'
        }
      }
      extensionProfile: {
        extensions: [
          {
            name: '${vmssName}-linuxscriptextension'
            properties: {
              publisher: 'Microsoft.OSTCExtensions'
              type: 'CustomScriptForLinux'
              typeHandlerVersion: '1.3'
              autoUpgradeMinorVersion: true
              settings: {
                fileUris: [
                  'https://${artifactstorage001.name}.blob.core.windows.net/${scriptsContainer.name}/forwarderSetup.sh'
                ]
              }
              protectedSettings: {
                commandToExecute: 'sh forwarderSetup.sh'
                storageAccountName: artifactstorage001.name
                storageAccountKey: listkeys(artifactstorage001.id, artifactstorage001.apiVersion).keys[0].value
              }
            }
          }
        ]
      }
    }
  }
}

// Outputs

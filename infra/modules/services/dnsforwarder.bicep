// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a DNS Forwarder on VMSS.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param subnetId string
param dnsForwarderName string
param storageAccountId string
param storageAccountContainerName string
param vmssSkuName string = 'Standard_A1_v2'
param vmssSkuTier string = 'Standard'
param vmssSkuCapacity int = 2
param vmssAdmininstratorUsername string = 'VmssMainUser'
@secure()
param vmssAdministratorPublicSshKey string

// Variables
var storageAccountName = length(split(storageAccountId, '/')) >= 9 ? last(split(storageAccountId, '/')) : 'incorrectSegmentLength'

// Resources
resource loadBalancer001 'Microsoft.Network/loadBalancers@2020-11-01' = {
  name: '${dnsForwarderName}-lb'
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Global'
  }
  properties: {
    backendAddressPools: [
      {
        name: '${dnsForwarderName}-backendpool'
      }
    ]
    frontendIPConfigurations: [
      {
        name: '${dnsForwarderName}-ipfrontend'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    inboundNatPools: [
      {
        name: '${dnsForwarderName}-natpool'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', '${dnsForwarderName}-lb', '${dnsForwarderName}-ipfrontend')
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
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', '${dnsForwarderName}-lb', '${dnsForwarderName}-backendpool')
          }
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', '${dnsForwarderName}-lb', '${dnsForwarderName}-ipfrontend')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', '${dnsForwarderName}-lb', '${dnsForwarderName}-probe')
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
        name: '${dnsForwarderName}-probe'
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
  name: '${dnsForwarderName}-sshKey'
  location: location
  tags: tags
  properties: {
    publicKey: vmssAdministratorPublicSshKey
  }
}

resource vmss001 'Microsoft.Compute/virtualMachineScaleSets@2020-12-01' = {
  name: dnsForwarderName
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
            name: '${dnsForwarderName}-nic'
            properties: {
              primary: true
              enableAcceleratedNetworking: false
              dnsSettings: {}
              enableIPForwarding: false
              enableFpga: false
              ipConfigurations: [
                {
                  name: '${dnsForwarderName}-ipconfig'
                  properties: {
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', '${dnsForwarderName}-lb', '${dnsForwarderName}-backendpool')
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', '${dnsForwarderName}-lb', '${dnsForwarderName}-natpool')
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
        computerNamePrefix: take(dnsForwarderName, 9)
        adminUsername: vmssAdmininstratorUsername
        linuxConfiguration: {
          disablePasswordAuthentication: true
          ssh: {
            publicKeys: [
              {
                keyData: sshPublicKey.properties.publicKey
                path: '/home/${vmssAdmininstratorUsername}/.ssh/authorized_keys'
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
            name: '${dnsForwarderName}-linuxscriptextension'
            properties: {
              publisher: 'Microsoft.OSTCExtensions'
              type: 'CustomScriptForLinux'
              typeHandlerVersion: '1.3'
              autoUpgradeMinorVersion: true
              settings: {
                fileUris: [
                  'https://${storageAccountName}.blob.core.windows.net/${storageAccountContainerName}/forwarderSetup.sh'
                ]
              }
              protectedSettings: {
                commandToExecute: 'sh forwarderSetup.sh'
                storageAccountName: storageAccountName
                storageAccountKey: listkeys(storageAccountId, '2021-02-01').keys[0].value
              }
            }
          }
        ]
      }
    }
  }
}

// Outputs

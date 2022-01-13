// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a Firewall Policy.
targetScope = 'resourceGroup'

// Parameters
param firewallPolicyName string

// Variables

// Resources
resource networkRules 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2020-11-01' = {
  name: '${firewallPolicyName}/networkrules-rulecollection'
  properties: {
    priority: 10000
    ruleCollections: [
      {
        name: 'MachineLearning-NetworkRules'
        priority: 10100
        action: {
          type: 'Allow'
        }
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        rules: [
          {
            name: 'MachineLearning-NetworkRule-001'
            ruleType: 'NetworkRule'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
            destinationAddresses: [
              'AzureActiveDirectory'
              'AzureMachineLearning'
              'AzureResourceManager'
              'Storage'
              'AzureKeyVault'
              'AzureContainerRegistry'
              'MicrosoftContainerRegistry'
              'AzureFrontDoor.FirstParty'
            ]
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: [
              '*'
            ]
            description: 'Allow outbound access to required services'
          }
        ]
      }
      {
        name: 'HDInsight-NetworkRules'
        priority: 10200
        action: {
          type: 'Allow'
        }
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        rules: [
          {
            name: 'HDInsight-NetworkRule-001'
            ruleType: 'NetworkRule'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
            destinationAddresses: [
              'Sql'
            ]
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: [
              '1433'
            ]
            description: 'Allow default SQL servers provided by HDInsight'
          }
          {
            name: 'HDInsight-NetworkRule-002'
            ruleType: 'NetworkRule'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
            destinationAddresses: [
              'AzureMonitor'
            ]
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: [
              '*'
            ]
            description: 'Allows scale feature of HDInsight'
          }
        ]
      }
      {
        name: 'Databricks-NetworkRules'
        priority: 10300
        action: {
          type: 'Allow'
        }
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        rules: [
          {
            name: 'Databricks-NetworkRule-001'
            ruleType: 'NetworkRule'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
            destinationAddresses: [
              'AzureActiveDirectory'
              'AzureFrontDoor.Frontend'
            ]
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: [
              '443'
            ]
            description: 'Allow OAuth flow for the User to the Workspace Private Endpoint and features like Mount Points, Credential Passthrough, etc.'
          }
          {
            name: 'Databricks-NetworkRule-002'
            ruleType: 'NetworkRule'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
            destinationAddresses: [
              'AzureDatabricks'
              'Storage'
            ]
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: [
              '443'
            ]
            description: 'Required for workers communication with Azure Storage services and Databricks Webapp'
          }
          {
            name: 'Databricks-NetworkRule-003'
            ruleType: 'NetworkRule'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
            destinationAddresses: [
              'Sql'
            ]
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: [
              '3306'
            ]
            description: 'Required for workers communication with Azure SQL services'
          }
          {
            name: 'Databricks-NetworkRule-004'
            ruleType: 'NetworkRule'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
            destinationAddresses: [
              'EventHub'
            ]
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: [
              '9093'
            ]
            description: 'Required for workers communication with Azure Eventhub services'
          }
        ]
      }
      {
        name: 'Azure-NetworkRules'
        priority: 10400
        action: {
          type: 'Allow'
        }
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        rules: [
          {
            name: 'Azure-NetworkRule-001'
            ruleType: 'NetworkRule'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
            destinationAddresses: [
              '23.102.135.246'  // Required IPs for Windows Activation (https://docs.microsoft.com/en-us/troubleshoot/azure/virtual-machines/custom-routes-enable-kms-activation#solution).
              '51.4.143.248'
              '23.97.0.13'
              '42.159.7.249'
            ]
            destinationIpGroups: []
            destinationFqdns: [
              // 'kms.core.windows.net'  // FQDNs instead of hardcoded IPs can only be used, if the firewall policy has the DNS forwrder setting turned on. For compatibility reasons we will rely on IPs.
              // 'kms.core.cloudapi.de'
              // 'kms.core.usgovcloudapi.net'
              // 'kms.core.chinacloudapi.cn'
            ]
            destinationPorts: [
              '1688'
            ]
            description: 'Allow Windows Activation in Azure through Azure KMS Service'
          }
        ]
      }
      {
        name: 'AzureDevOps-NetworkRules'
        priority: 10500
        action: {
          type: 'Allow'
        }
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        rules: [
          {
            name: 'AzureDevOps-NetworkRule-001'
            ruleType: 'NetworkRule'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
            destinationAddresses: [
              '13.107.6.0/24'
              '13.107.9.0/24'
              '13.107.42.0/24'
              '13.107.43.0/24'
            ]
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: [
              '443'
            ]
            description: 'Allow Self-hosted DevOps Agents to poll for pending jobs'
          }
        ]
      }
    ]
  }
}

resource applicationRules 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2020-11-01' = {
  name: '${firewallPolicyName}/applicationrules-rulecollection'
  dependsOn: [
    networkRules
  ]
  properties: {
    priority: 20000
    ruleCollections: [
      {
        name: 'MachineLearning-ApplicationRules'
        priority: 20100
        action: {
          'type': 'Allow'
        }
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        rules: [
          {
            name: 'MachineLearning-ApplicationRule-001'
            ruleType: 'ApplicationRule'
            protocols: [
              {
                protocolType: 'Http'
                port: 80
              }
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            fqdnTags: []
            targetFqdns: [
              'anaconda.com'
              '*.anaconda.com'
              '*.anaconda.org'
              'pypi.org'
              'cloud.r-project.org'
              '*pytorch.org'
              '*.tensorflow.org'
              'update.code.visualstudio.com'
              '*.vo.msecnd.net'
              '*.instances.azureml.net'
              '*.instances.azureml.ms'
            ]
            targetUrls: []
            terminateTLS: false
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: []
            sourceIpGroups: []
            description: 'MachineLearning allow common FQDNs'
          }
        ]
      }
      {
        name: 'HDInsight-ApplicationRules'
        priority: 20200
        action: {
          'type': 'Allow'
        }
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        rules: [
          {
            name: 'HDInsight-ApplicationRule-001'
            ruleType: 'ApplicationRule'
            protocols: [
              {
                protocolType: 'Http'
                port: 80
              }
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            fqdnTags: [
              'HDInsight'
              'WindowsUpdate'
            ]
            targetFqdns: []
            targetUrls: []
            terminateTLS: false
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: []
            sourceIpGroups: []
            description: 'HDInsight Service Tag Rule'
          }
          {
            name: 'HDInsight-ApplicationRule-002'
            ruleType: 'ApplicationRule'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            fqdnTags: []
            targetFqdns: [
              #disable-next-line no-hardcoded-env-urls
              'login.microsoftonline.com'
              'login.windows.net'
            ]
            targetUrls: []
            terminateTLS: false
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: []
            sourceIpGroups: []
            description: 'Allows Windows login activity'
          }
        ]
      }
      {
        name: 'DataFactory-ApplicationRules'
        priority: 20300
        action: {
          type: 'Allow'
        }
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        rules: [
          {
            name: 'DataFactory-ApplicationRule-001'
            ruleType: 'ApplicationRule'
            protocols: [
              {
                protocolType: 'Http'
                port: 80
              }
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            fqdnTags: []
            targetFqdns: [
              'go.microsoft.com'
              'download.microsoft.com'
              'browser.events.data.msn.com'
              '*.clouddatahub.net'
            ]
            targetUrls: []
            terminateTLS: false
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: []
            sourceIpGroups: []
            description: 'Allows download of Self-hosted Integration Runtime installer and updates'
          }
          {
            name: 'DataFactory-ApplicationRule-002'
            ruleType: 'ApplicationRule'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            fqdnTags: []
            targetFqdns: [
              '*.servicebus.windows.net'
            ]
            targetUrls: []
            terminateTLS: false
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: []
            sourceIpGroups: []
            description: 'Allows interactive authoring and logging with Self-hosted Integration Runtime and Azure SSIS'
          }
          {
            name: 'DataFactory-ApplicationRule-003'
            ruleType: 'ApplicationRule'
            protocols: [
              {
                protocolType: 'Http'
                port: 80
              }
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            fqdnTags: []
            targetFqdns: [
              '*.githubusercontent.com'
            ]
            targetUrls: []
            terminateTLS: false
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: []
            sourceIpGroups: []
            description: 'Allows download of SHIR install script from GitHub'
          }
        ]
      }
      {
        name: 'Databricks-ApplicationRules'
        priority: 20400
        action: {
          type: 'Allow'
        }
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        rules: [
          {
            name: 'Databricks-ApplicationRule-001'
            ruleType: 'ApplicationRule'
            protocols: [
              {
                protocolType: 'Http'
                port: 80
              }
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            fqdnTags: []
            targetFqdns: [
              'tunnel.australiaeast.azuredatabricks.net'
              'tunnel.brazilsouth.azuredatabricks.net'
              'tunnel.canadacentral.azuredatabricks.net'
              'tunnel.centralindia.azuredatabricks.net'
              'tunnel.eastus2.azuredatabricks.net'
              'tunnel.eastus2c2.azuredatabricks.net'
              'tunnel.eastusc3.azuredatabricks.net'
              'tunnel.centralusc2.azuredatabricks.net'
              'tunnel.northcentralusc2.azuredatabricks.net'
              'tunnel.southeastasia.azuredatabricks.net'
              'tunnel.francecentral.azuredatabricks.net'
              'tunnel.japaneast.azuredatabricks.net'
              'tunnel.koreacentral.azuredatabricks.net'
              'tunnel.northeuropec2.azuredatabricks.net'
              'tunnel.westus.azuredatabricks.net'
              'tunnel.westeurope.azuredatabricks.net'
              'tunnel.westeuropec2.azuredatabricks.net'
              'tunnel.southafricanorth.azuredatabricks.net'
              'tunnel.switzerlandnorth.azuredatabricks.net'
              'tunnel.uaenorth.azuredatabricks.net'
              'tunnel.ukwest.azuredatabricks.net'
            ]
            targetUrls: []
            terminateTLS: false
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: []
            sourceIpGroups: []
            description: 'Allows Secure Cluster Connectivity option'
          }
          {
            name: 'Databricks-ApplicationRule-002'
            ruleType: 'ApplicationRule'
            protocols: [
              {
                protocolType: 'Http'
                port: 80
              }
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            fqdnTags: []
            targetFqdns: [
              'archive.ubuntu.com'
              'github.com'
              '*.maven.apache.org'
              'conjars.org'
            ]
            targetUrls: []
            terminateTLS: false
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: []
            sourceIpGroups: []
            description: 'Allows Databricks Setup Notebook to run successfully'
          }
        ]
      }
      {
        name: 'Azure-ApplicationRules'
        priority: 20500
        action: {
          type: 'Allow'
        }
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        rules: [
          {
            name: 'Azure-ApplicationRule-001'
            ruleType: 'ApplicationRule'
            protocols: [
              {
                protocolType: 'Http'
                port: 80
              }
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            fqdnTags: []
            targetFqdns: [
              '*microsoft.com'
              '*azure.com'
              '*windows.com'
              '*windows.net'
              '*azure-automation.net'
              '*digicert.com'
            ]
            targetUrls: []
            terminateTLS: false
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: []
            sourceIpGroups: []
            description: 'Allows communication with Azure and Microsoft for Logging and Metrics as well as other services'
          }
        ]
      }
      {
        name: 'AzureDevOps-ApplicationRules'
        priority: 20600
        action: {
          type: 'Allow'
        }
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        rules: [
          {
            name: 'AzureDevOps-ApplicationRule-001'
            ruleType: 'ApplicationRule'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            fqdnTags: []
            targetFqdns: [
              '*snapcraft.io'
              'vstsagentpackage.azureedge.net'
            ]
            targetUrls: []
            terminateTLS: false
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: []
            sourceIpGroups: []
            description: 'Allows installation of Visual Studio DevOps Agent extension'
          }
        ]
      }
    ]
  }
}

// Outputs

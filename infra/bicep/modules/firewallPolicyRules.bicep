// This template is used as a module from the network.bicep template. 
// The module contains a template to create firewall policy rules.
targetScope = 'resourceGroup'

// Parameters
param firewallPolicyName string
param location string

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
            description: 'Allows interactive authoring with Self-hosted Integration Runtime'
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
            ]
            targetUrls: []
            terminateTLS: false
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: []
            sourceIpGroups: []
            description: 'Allows communication with azure and microsoft'
          }
        ]
      }
    ]
  }
}

// Outputs

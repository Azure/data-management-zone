# Limiting Cross-Tenant Private Endpoint Connections

Customers are increasingly using private endpoints in their tenants to connect to their PaaS services privately and securely. Some users have the perception that the use of Private Endpoints automatically prevents any data exfiltration risks. However, this is an incorrect assumption and highly depends on the overall configuration of the respective scope in the tenant. Therefore, this paper will recommend configuration options to achieve the desired security level and meet the data leakage prevention (DLP) controls inside your Azure environment.

## Introduction

Private Endpoints can be used to control the traffic within a customer Azure environement using an existing network perimeter, however even using private endpoints within Azure there is still a  potential risk of data exfiltration. This risk arises from the fact that a rogue user could:

*	Scenario A: Create endpoints on the customer virtual network, which are linked to services that are hosted outside the customer environment (other subscription and/or tenant) or
*	Scenario B: Create private endpoints in other subscriptions and tenants that are linked to services that are hosted in the customer environment.

![Data exfiltration scenarios](/docs/images/CrossTenantPrivateEndpointProvisioning.png)

For both scenarios, it is as simple as specifying the resource ID of the service and manually approving the private endpoint connection on the respective service. In addition, the user requires some RBAC access to execute these actions. This will be further specified in the sections below.

Solutions for these scenarios are of high interest to companies within highly regulated industries such as health care and finance who are required to enforce stricter levels of control on internal users administering their cloud service provider (CSP) environments.

The following sections will therefore propose options to overcome the respective scenarios mentioned above.

## Scenario A: Deny Private Endpoints from other tenants and subscriptions

### Scenario

For the first data exfiltration scenario, a rogue user requires the following rights in the customer environment:

1.	“Microsoft.Network/virtualNetworks/join/action” rights on a subnet with “privateEndpointNetworkPolicies” set to “Disabled” and
2.	“Microsoft.Network/privateEndpoints/write” access to a resource group in the customer environment.

With these rights, the person has the possibility to create a private endpoint that is linked to a service in a separate subscription and tenant. The scenario is illustrated in Figure 1: Data exfiltration scenarios.

To do so, the user first needs to setup an external tenant and subscription. As a next step, the private endpoint needs to be created in the customer environment, by manually specifying the resource id of the service. Finally, the person needs to approve the private endpoint on the linked service hosted in the external tenant to allow traffic over the connection.

Once the private endpoint is approved by the user, data can be exfiltrated over the corporate virtual network, in case access was granted via Azure RBAC.

### Mitigation

To ensure a scalable approach we will follow best practices and principles defined by the [Enterprise-Scale architecture by Microsoft](https://github.com/Azure/Enterprise-Scale). Therefore, we will focus on policies as a mean to solve the aforementioned scenario.

Customer can use the following [policy definition](/infra/Policies/PolicyDefinitions/PrivateEndpoint/params.policyDefinition.Deny-PrivateEndpoint-PrivateLinkServiceConnections.json), to automatically deny the first data exfiltration scenario across a tenant:

```json
"if": {
    "allOf": [
        {
            "field": "type",
            "equals": "Microsoft.Network/privateEndpoints"
        },
        {
            "anyOf": [
                {
                    "count": {
                        "field": "Microsoft.Network/privateEndpoints/manualprivateLinkServiceConnections[*]",
                        "where": {
                            "allOf": [
                                {
                                    "field": "Microsoft.Network/privateEndpoints/manualprivateLinkServiceConnections[*].privateLinkServiceId",
                                    "notEquals": ""
                                },
                                {
                                    "value": "[split(concat(first(field('Microsoft.Network/privateEndpoints/manualprivateLinkServiceConnections[*].privateLinkServiceId')), '//'), '/')[2]]",
                                    "notEquals": "[subscription().subscriptionId]"
                                }
                            ]
                        }
                    },
                    "greaterOrEquals": 1
                },
                {
                    "count": {
                        "field": "Microsoft.Network/privateEndpoints/privateLinkServiceConnections[*]",
                        "where": {
                            "allOf": [
                                {
                                    "field": "Microsoft.Network/privateEndpoints/privateLinkServiceConnections[*].privateLinkServiceId",
                                    "notEquals": ""
                                },
                                {
                                    "value": "[split(concat(first(field('Microsoft.Network/privateEndpoints/privateLinkServiceConnections[*].privateLinkServiceId')), '//'), '/')[2]]",
                                    "notEquals": "[subscription().subscriptionId]"
                                }
                            ]
                        }
                    },
                    "greaterOrEquals": 1
                }
            ]
        }
    ]
},
"then": {
    "effect": "Deny"
}
```

The policy shown above denies any private endpoints being created outside of the subscription of the linked service (Scenario A and D). The policy also provides the flexibility to use manualprivateLinkServiceConnections as well as privateLinkServiceConnections within the same subscription.

This policy can be changed so that private endpoints are only allowed to be created inside a certain set of subscriptions. This can be done by adding a parameter of type List and by using the "notIn": "[parameters('allowedSubscriptions')]" construct. However, this is not the recommended approach as this would mean that customers would have to constantly maintain the list of subscriptions for this policy. Whenever a new subscription gets created inside the customer tenant, the subscription ID would have to be added to the parameter.

It is recommended to assign the policy to the top-level management group and use exemptions where required.

### Affected scenarios by the policy definition

The policy shown above blocks the creation of private endpoints in a different subscription than the service itself (Scenario A and D). If this is a requirement for certain use-cases, we are recommending using policy exemptions. There are no other known patterns that are blocked by this policy definition.

## Scenario B: Deny private endpoints being created in other tenants and subscriptions

### Scenario

For the second scenario, a rogue user requires the following rights in the customer environment:

1.	“*/write” rights on the service in the customer environment to which a private endpoint should be created.

With these rights, the person has the possibility to create a private endpoint in an external tenant and subscription that is linked to a service in the customer environment. The scenario is illustrated in Figure 1: Data exfiltration scenarios.

Again, the user first needs to first setup an external private tenant and subscription. As a next step, the private endpoint needs to be created in the environment of the rogue user, by manually specifying the resource id and group id of the service. Finally, the person needs to approve the private endpoint on the linked service to allow traffic over the connection.

Once the private endpoint is approved by the user, data can be exfiltrated over the corporate virtual network, in case access was granted via Azure RBAC.

### Mitigation

To ensure a scalable approach we will follow best practices and principles defined by the [Enterprise-Scale architecture by Microsoft](https://github.com/Azure/Enterprise-Scale). Therefore, we will focus on policies as a mean to solve the aforementioned scenario.

Similarly, service specific policies could be used to deny these scenarios across the customer tenant. Private endpoint connections are sub-resources of the respective services and therefore show up under the properties section of the respective service. Incompliant connections can be denied using the following [policy definition (example for Azure Storage)](/infra/Policies/PolicyDefinitions/Storage/params.policyDefinition.Deny-Storage-PrivateEndpointConnections.json):

```json
"if": {
    "allOf": [
        {
            "field": "type",
            "equals": "Microsoft.Storage/storageAccounts/privateEndpointConnections"
        },
        {
            "field": "Microsoft.Storage/storageAccounts/privateEndpointConnections/privateLinkServiceConnectionState.status",
            "equals": "Approved"
        },
        {
            "anyOf": [
                {
                    "field": "Microsoft.Storage/storageAccounts/privateEndpointConnections/privateEndpoint.id",
                    "exists": false
                },
                {
                    "value": "[split(concat(field('Microsoft.Storage/storageAccounts/privateEndpointConnections/privateEndpoint.id'), '//'), '/')[2]]",
                    "notEquals": "[subscription().subscriptionId]"
                }
            ]
        }
    ]
},
"then": {
    "effect": "Deny"
}
```

The policy above shows an example for Azure Storage. The same policy definition needs to be replicated for other services such as [Key Vault](/infra/Policies/PolicyDefinitions/KeyVault/params.policyDefinition.Deny-KeyVault-PrivateEndpointConnections.json), [Cognitive Services](/infra/Policies/PolicyDefinitions/CognitiveServices/params.policyDefinition.Deny-CognitiveServices-PrivateEndpointConnections.json), [SQL Server](/infra/Policies/PolicyDefinitions/Sql/params.policyDefinition.Deny-Sql-PrivateEndpointConnections.json) etc. The policy denies the approval of private endpoint connections to private endpoints that are hosted outside of the subscription of the respective service. It does not deny the rejection or removal of private endpoint connections, which is the desired behavior of customers. Auto-approval workflows are also not affected by this policy (Scenario C). Sadly, the approval of compliant private endpoint connections within the portal is blocked with this method, because the portal UI does not send the resource ID of the connected private endpoint in their payload. Therefore, we are advising customers to use [ARM (storage example)](/infra/Policies/PolicyDefinitions/Storage/SampleDeployPrivateEndpointConnection) for approving the private endpoint connection.

It is recommended to assign the policy to the top-level management group and use exemptions where required.

### Affected scenarios by the policy definition

With the introduction of managed virtual networks and managed private endpoints in Synapse and Data Factory as well as managed private endpoints, this policy is blocking the secure and private usage of these services. In general, this means that the development of (data) solutions on top of these services will be blocked across the tenant.

Therefore, we are proposing the use of an “Audit” effect instead of a “Deny” affect in [Scenario B: Deny private endpoints being created in other tenants and subscriptions](#) to keep track of private endpoints being created in separate subscriptions and tenants or to use policy exemptions for the respective data platform scopes. Additional policies must be created for Data Factory and Synapse to overcome the data exfiltration risk on these managed virtual networks that are hosted in a Microsoft subscription. How this can be done will be described in the next paragraphs.

### Azure Data Factory

To overcome the Scenario A on the managed virtual network of Data Factory, customers can use the following [policy definition](/infra/Policies/PolicyDefinitions/DataFactory/params.policyDefinition.Deny-DataFactory-ManagedPrivateEndpoints.json):

```json
"if": {
    "allOf": [
        {
            "field": "type",
            "equals": "Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints"
        },
        {
            "anyOf": [
                {
                    "field": "Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints/privateLinkResourceId",
                    "exists": false
                },
                {
                    "value": "[split(field('Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints/privateLinkResourceId'), '/')[2]]",
                    "notEquals": "[subscription().subscriptionId]"
                }
            ]
        }
    ]
},
"then": {
    "effect": "[parameters('effect')]"
}
```

The policy shown above mitigates the data exfiltration risk for managed virtual networks of Data Factory, by denying private endpoints that are linked to services that are hosted outside the subscription of the data factory. With Enterprise-Scale analytics it is expected that private endpoints will also be created to services that are hosted outside of the subscription of the Data Factory. Therefore, this policy can also be changed to allow a connection to services hosted in a set of subscriptions by adding a parameter of type List and by using the "notIn": "[parameters('allowedSubscriptions')]" construct. This change is recommended for the data platform scope inside the tenant.

It is recommended to assign the policy shown above to the top-level management group and use exemptions where required. For the data platform, it is recommended to make the changes mentioned above and assign the policy to the set of data platform subscriptions.

### Azure Synapse

Azure Synapse also uses managed virtual networks and therefore a similar policy to the one proposed for Data Factory must be applied to cover Scenario A. Azure Synapse does not provide a policy alias for managed private endpoints, but introduced a data exfiltration feature, which can be enforced for workspaces via the following policy:

```json
"if": {
    "allOf": [
        {
            "field": "type",
            "equals": "Microsoft.Synapse/workspaces"
        },
        {
            "anyOf": [
                {
                    "field": "Microsoft.Synapse/workspaces/managedVirtualNetworkSettings.preventDataExfiltration",
                    "exists": false
                },
                {
                    "field": "Microsoft.Synapse/workspaces/managedVirtualNetworkSettings.preventDataExfiltration",
                    "notEquals": true
                },
                {
                    "count": {
                        "field": "Microsoft.Synapse/workspaces/managedVirtualNetworkSettings.allowedAadTenantIdsForLinking[*]",
                        "where": {
                            "field": "Microsoft.Synapse/workspaces/managedVirtualNetworkSettings.allowedAadTenantIdsForLinking[*]",
                            "notEquals": "[subscription().tenantId]"
                        }
                    },
                    "greaterOrEquals": 1
                }
            ]
        }
    ]
},
"then": {
    "effect": "Deny"
}
```

The policy above enforces the use of the data exfiltration feature of Synapse. Synapse also allows to deny any private endpoint that is coming from a service that is hosted outside of the customer tenant or a specified set of tenant ids. The policy above enforces exactly that and only allows the creation of managed private endpoints that are linked to services that are hosted in the customer tenant.

These policies are now available as built-in:

1.	Azure Synapse workspaces should allow outbound data traffic only to approved targets

    Definition ID: /providers/Microsoft.Authorization/policyDefinitions/3484ce98-c0c5-4c83-994b-c5ac24785218

2.	Synapse managed private endpoints should only connect to resources in approved Azure Active Directory tenants

    Definition ID: “/providers/Microsoft.Authorization/policyDefinitions/3a003702-13d2-4679-941b-937e58c443f0”

It is recommended to assign the policy to the top-level management group and use exemptions where required.

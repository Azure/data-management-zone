# Enterprise Scale Analytics - Data Management

> **General disclaimer:** Please be aware that this template is in private preview. Therefore, expect smaller bugs and issues when working with the solution. Please submit an Issue in GitHub if you come across any issues that you would like us to fix.

## Description

The Data Management template is, as the name suggests, classified as a management function and is at the heart of the [**Enterprise Scale Analytics and AI**](https://github.com/Azure/Enterprise-Scale-Analytics) solution pattern. It is responsible for the governance of the platform and enables communication to ingest data sources from Azure, third-party clouds and on-premises data sources.

## What will be deployed?

By default, all the services which come under Data Management Zone are enabled, and you must explicitly disable services that you don't want to be deployed.

> **Note:** Before deploying the resources, we recommend to check registration status of the required resource providers in your subscription. For more information, see [Resource providers for Azure services](https://docs.microsoft.com/azure/azure-resource-manager/management/resource-providers-and-types).

![Data Management Zone](./docs/images/DataHub.png)

- [Virtual Network](https://docs.microsoft.com/azure/virtual-network/virtual-networks-overview)
- [Network Security Groups](https://docs.microsoft.com/azure/virtual-network/network-security-groups-overview)
- [Route Tables](https://docs.microsoft.com/azure/virtual-network/virtual-networks-udr-overview)
- [Azure Firewall](https://docs.microsoft.com/azure/firewall/overview)
- [Firewall Policy](https://docs.microsoft.com/azure/firewall-manager/policy-overview#:~:text=Firewall%20Policy%20is%20an%20Azure,work%20across%20regions%20and%20subscriptions.)
- [Private DNS Zones](https://docs.microsoft.com/azure/dns/private-dns-privatednszone#:~:text=By%20using%20private%20DNS%20zones,that%20are%20linked%20to%20it.)
- [Container Registry](https://docs.microsoft.com/azure/container-registry/)
- [Purview](https://docs.microsoft.com/azure/purview/)
- [Key Vault](https://docs.microsoft.com/azure/key-vault/general)
- [Storage Account](https://docs.microsoft.com/azure/storage/common/storage-account-overview)
- [Synapse Private Link Hub](https://docs.microsoft.com/azure/synapse-analytics/security/synapse-private-link-hubs)
- [PowerBI](https://docs.microsoft.com/power-bi/fundamentals/power-bi-overview)
- [Policies](https://docs.microsoft.com/azure/governance/policy/overview)

For more details regarding the services that will be deployed, please read the [Data Management](https://github.com/Azure/Enterprise-Scale-Analytics/blob/main/docs/02-datamanagement/01-overview.md) guide in the Enterprise Scale Analytics documentation.

You have two options for deploying this reference architecture:

1. Use the `Deploy to Azure` button for an immediate deployment
2. Use GitHub Actions or Azure DevOps Pipelines for an automated, repeatable deployment

## Option 1: Deploy to Azure - Quickstart (Coming soon ...)



## Navigation Menu

* [Prerequisites](./docs/ESA-ManagementZone-Prerequisites.md)
* Option 1: Deploy to Azure - Quickstart (Coming soon ..)

| Data Management Zone |
|:---------------------|
<!-- [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-management-zone%2Fmain%2Finfra%2Fmain.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-management-zone%2Fmain%2Fdocs%2Freference%2Fportal.enterpriseScaleAnalytics.json) -->
![Deploy to Azure](/docs/images/deploytoazuregrey.png)

* Option 2: Deploy reference implementation :
  * [Prepare the deployment](./docs/ESA-ManagementZone-PrepareDeployment.md)
  * [Using Azure DevOps](./docs/ESA-ManagementZone-DeployUsingAzureDevops.md)
  * [Using GitHub Actions](./docs/ESA-ManagementZone-DeployUsingGithubActions.md)
* [Code Structure](./docs/ESA-ManagementZone-CodeStructure.md)
* [Known issues](./docs/ESA-ManagementZone-KnownIssues.md)

### Enterprise Scale Analytics and AI - Documentation and Implementation

- [Documentation](https://github.com/Azure/Enterprise-Scale-Analytics)
- [Implementation - Data Management](https://github.com/Azure/data-management-zone)
- [Implementation - Data Landing Zone](https://github.com/Azure/data-landing-zone)
- [Implementation - Data Integration - Batch](https://github.com/Azure/data-integration-batch)
- [Implementation - Data Integration - Streaming](https://github.com/Azure/data-integration-streaming)
- [Implementation - Data Product - Reporting](https://github.com/Azure/data-product-reporting)
- [Implementation - Data Product - Analytics & Data Science](https://github.com/Azure/data-product-analytics)

## Contributing

This project welcomes contributions and suggestions. Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit <https://cla.opensource.microsoft.com>.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repositories using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

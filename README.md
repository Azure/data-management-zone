# Enterprise Scale Analytics - Data Management

## Objective

The Enterprise-Scale Analytics architecture provides prescriptive guidance coupled with Azure best practices, and it follows design principles across the critical design areas for organizations to define their Azure data platform architecture. It will continue to evolve alongside the Azure platform and is ultimately defined by the various design decisions that organizations must make to define their Azure data journey.

The Enterprise-Scale Analytics architecture consists of two core building blocks: Data Management Zone and Data Landing Zone. The architecture is modular by design and allows organizations to start small with a single Data Mangagement Zone and Single Data Landing Zone and allows them to scale by adding more Data Landing Zones to their architecture. If core recommendations are followed, the resulting target architecture will put the customer on a path to sustainable scale.

![Enterprise-Scale Analytics](/docs/images/EnterpriseScaleAnalytics.gif)

---

_The Enterprise-Scale Analytics architecture represents the strategic design path and target technical state for your Azure data environment._

---

This respository describes the Data Management Zone, which is classified as data management hub. It is the heart of the **Enterprise Scale Analytics** architecture pattern and enables central governance of data assets across all Data Landing Zones.

## Deploy Enterprise Scale Analytics

The Enterprise-Scale Analytics architecture is modular by design and allows customers to start with a small footprint and grow over time. In order to not end up in a migration project, customers should decide upfront how they want to organize data across Data Landing Zones. All Enterprise-Scale Analytics architecture building blocks can be deployed through the Azure Portal as well as through GitHub Actions workflows and Azure DevOps Pipelines. The template repositories contain sample YAML pipelines in order to more quickly get started.

| Reference implementation   | Description | Deploy to Azure | Link |
|:---------------------------|:------------|:----------------|------|
| Enterprise-Scale Analytics | Deploys a Data Management Zone and one or multiple Data Landing Zones all at once. Provides less options than the the individual Data Management Zone and Data Landing Zone deployment options. Helps you to quickly get started and make yourself familiar with the reference design. For more advanced scenarios, please deploy the artifacts individually. |[![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-management-zone%2Fmain%2Fdocs%2Freference%2FenterpriseScaleAnalytics.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-management-zone%2Fmain%2Fdocs%2Freference%2Fportal.enterpriseScaleAnalytics.json) |  |
| Data Management Zone       | Deploys a single Data Management Zone to a subscription. |[![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-management-zone%2Fmain%2Finfra%2Fmain.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-management-zone%2Fmain%2Fdocs%2Freference%2Fportal.dataManagementZone.json) | [Repository](https://github.com/Azure/data-management-zone) |
| Data Landing Zone          | Deploys a single Data Landing Zone to a subscription. |[![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-landing-zone%2Fmain%2Finfra%2Fmain.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-landing-zone%2Fmain%2Fdocs%2Freference%2Fportal.dataLandingZone.json) | [Repository](https://github.com/Azure/data-landing-zone) |
| Data Integration Batch     | Deploys a Data Workload template for Data Batch Analysis to a resource group. |[![Deploy To Azure](https://aka.ms/deploytoazurebutton)](/) | [Repository](https://github.com/Azure/data-integration-batch) |
| Data Integration Streaming | Deploys a Data Workload template for Data Streaming Analysis to a resource group. |[![Deploy To Azure](https://aka.ms/deploytoazurebutton)](/) | [Repository](https://github.com/Azure/data-integration-streaming) |
| Data Product Analytics     | Deploys a Data Workload template for Data Analytics and Data Science to a resource group. |[![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-product-analytics%2Fmain%2Finfra%2Fmain.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-product-analytics%2Fmain%2Fdocs%2Freference%2Fportal.dataProduct.json) | [Repository](https://github.com/Azure/data-product-analytics) |

## Deploy Data Management Zone

To deploy the Data Management Zone Deployment into your Azure Subscription, please follow the step-by-step instructions:

1. [Prerequisites](/docs/EnterpriseScaleAnalytics-Prerequisites.md)
2. [Create repository](/docs/EnterpriseScaleAnalytics-CreateRepository.md)
3. [Setting up Service Principal](/docs/EnterpriseScaleAnalytics-ServicePrincipal.md)
4. Template Deployment
    1. [GitHub Action Deployment](/docs/EnterpriseScaleAnalytics-GitHubActionsDeployment.md)
    2. [Azure DevOps Deployment](/docs/EnterpriseScaleAnalytics-AzureDevOpsDeployment.md)
5. [Known Issues](/docs/EnterpriseScaleAnalytics-KnownIssues.md)

## Contributing

This project welcomes contributions and suggestions. Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit <https://cla.opensource.microsoft.com>.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repositories using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

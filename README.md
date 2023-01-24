# Cloud-Scale Analytics Scenario - Data Management Zone

## Objective

The [Cloud-Scale Analytics Scenario](https://aka.ms/adopt/cloudscaleanalytics) provides a prescriptive data platform design coupled with Azure best practices and design principles. These principles serve as a compass for subsequent design decisions across critical technical domains. The architecture will continue to evolve alongside the Azure platform and is ultimately driven by the various design decisions that organizations must make to define their Azure data journey.

The Cloud-scale Analytics architecture consists of two core building blocks:

1. *Data Management Landing Zone* which provides all data management and data governance capabilities for the data platform of an organization.
1. *Data Landing Zone* which is a logical construct and a unit of scale in the Cloud-scale Analytics architecture that enables data retention and execution of data workloads for generating insights and value with data.

The architecture is modular by design and allows organizations to start small with a single Data Management Landing Zone and Data Landing Zone, but also allows to scale to a multi-subscription data platform environment by adding more Data Landing Zones to the architecture. Thereby, the reference design allows to implement different modern data platform patterns like data-mesh, data-fabric as well as traditional datalake architectures. Cloud-scale Analytics has been very well aligned with the data-mesh approach, and is ideally suited to help organizations build data products and share these across business units of an organization. If core recommendations are followed, the resulting target architecture will put the customer on a path to sustainable scale.

![Cloud-scale Analytics](/docs/images/CloudScaleAnalytics.gif)

---

*The Cloud-scale Analytics architecture represents the strategic design path and target technical state for your Azure data platform.*

---

This repository describes the Data Management Landing Zone, which is classified as data management hub. It is the heart of the Cloud-scale Analytics architecture pattern and enables central governance of data assets across all Data Landing Zones. Data Management and Analytics scenario targets the deployment of a single Data Management Landing Zone instance inside a tenant of an organization.

> **Note:** Before getting started with the deployment, please make sure you are familiar with the [complementary documentation in the Cloud Adoption Framework](https://aka.ms/adopt/datamanagement). After deploying your Data Management Landing Zone, please move on to the [Data Landing Zone](https://github.com/Azure/data-landing-zone) deployment to create an environment in which you can start working on generating insights and value with data. The minimal recommended setup consists of a single Data Management Landing Zone and a single [Data Landing Zone](https://github.com/Azure/data-landing-zone).

## Deploy Cloud-Scale Analytics Scenario

The Cloud-scale Analytics architecture is modular by design and allows customers to start with a small footprint and grow over time. In order to not end up in a migration project, customers should decide upfront how they want to organize data domains across Data Landing Zones. All Cloud-scale Analytics architecture building blocks can be deployed through the Azure Portal as well as through GitHub Actions workflows and Azure DevOps Pipelines. The template repositories contain sample YAML pipelines to more quickly get started with the setup of the environments.

| Reference implementation   | Description | Deploy to Azure | Link |
|:---------------------------|:------------|:----------------|------|
| Cloud-Scale Analytics Scenario | Deploys a Data Management Landing Zone and one or multiple [Data Landing Zone](https://github.com/Azure/data-landing-zone) all at once. Provides less options than the the individual Data Management Landing Zone and Data Landing Zone deployment options. Helps you to quickly get started and make yourself familiar with the reference design. For more advanced scenarios, please deploy the artifacts individually. |[![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-management-zone%2Fmain%2Fdocs%2Freference%2FdataManagementAnalytics.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-management-zone%2Fmain%2Fdocs%2Freference%2Fportal.dataManagementAnalytics.json) |  |
| Data Management Landing Zone       | Deploys a single Data Management Landing Zone to a subscription. |[![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-management-zone%2Fmain%2Finfra%2Fmain.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-management-zone%2Fmain%2Fdocs%2Freference%2Fportal.dataManagementZone.json) | [Repository](https://github.com/Azure/data-management-zone) |
| Data Landing Zone          | Deploys a single Data Landing Zone to a subscription. Please deploy a Data Management Landing Zone first. |[![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-landing-zone%2Fmain%2Finfra%2Fmain.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-landing-zone%2Fmain%2Fdocs%2Freference%2Fportal.dataLandingZone.json) | [Repository](https://github.com/Azure/data-landing-zone) |
| Data Product Batch     | Deploys a Data Workload template for Data Batch Analysis to a resource group inside a [Data Landing Zone](https://github.com/Azure/data-landing-zone). Please deploy a Data Management Landing Zone and [Data Landing Zone](https://github.com/Azure/data-landing-zone) first. |[![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-product-batch%2Fmain%2Finfra%2Fmain.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-product-batch%2Fmain%2Fdocs%2Freference%2Fportal.dataProduct.json) | [Repository](https://github.com/Azure/data-product-batch) |
| Data Product Streaming | Deploys a Data Workload template for Data Streaming Analysis to a resource group inside a [Data Landing Zone](https://github.com/Azure/data-landing-zone). Please deploy a Data Management Landing Zone and [Data Landing Zone](https://github.com/Azure/data-landing-zone) first. |[![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-product-streaming%2Fmain%2Finfra%2Fmain.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-product-streaming%2Fmain%2Fdocs%2Freference%2Fportal.dataProduct.json) | [Repository](https://github.com/Azure/data-product-streaming) |
| Data Product Analytics     | Deploys a Data Workload template for Data Analytics and Data Science to a resource group inside a [Data Landing Zone](https://github.com/Azure/data-landing-zone). Please deploy a Data Management Landing Zone and [Data Landing Zone](https://github.com/Azure/data-landing-zone) first. |[![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-product-analytics%2Fmain%2Finfra%2Fmain.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-product-analytics%2Fmain%2Fdocs%2Freference%2Fportal.dataProduct.json) | [Repository](https://github.com/Azure/data-product-analytics) |

## Deploy Data Management Landing Zone

To deploy the Data Management Landing Zone into your Azure Subscription, please follow the step-by-step instructions:

1. [Prerequisites](/docs/DataManagementAnalytics-Prerequisites.md)
2. [Create repository](/docs/DataManagementAnalytics-CreateRepository.md)
3. [Setting up Service Principal](/docs/DataManagementAnalytics-ServicePrincipal.md)
4. Template Deployment
    1. [GitHub Action Deployment](/docs/DataManagementAnalytics-GitHubActionsDeployment.md)
    2. [Azure DevOps Deployment](/docs/DataManagementAnalytics-AzureDevOpsDeployment.md)
5. [Known Issues](/docs/DataManagementAnalytics-KnownIssues.md)

## Contributing

Please review the [Contributor's Guide](./CONTRIBUTING.md) for more information on how to contribute to this project via Issue Reports and Pull Requests.

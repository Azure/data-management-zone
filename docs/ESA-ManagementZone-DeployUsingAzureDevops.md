# Deploy reference implementation using Azure DevOps

## 1. Resource deployment

If you want to use Azure DevOps Pipelines for deploying the resources, you need to create an Azure Resource Manager service connection. To do so, execute the following steps:

1. First, you need to create an Azure DevOps Project. Instructions can be found [here](https://docs.microsoft.com/azure/devops/organizations/projects/create-project?view=azure-devops&tabs=preview-page).
1. In Azure DevOps, open the **Project settings**.
1. Now, select the **Service connections** page from the project settings page.
1. Choose **New service connection** and select **Azure Resource Manager**.

   ![ARM Connection](images/ARMConnectionDevOps.png)

1. On the next page select **Service principal (manual)**.
1. Select the appropriate environment to which you would like to deploy the templates. Only the default option **Azure Cloud** is currently supported.
1. For the **Scope Level**, select **Subscription** and enter your `subscription Id` and `name`.
1. Enter the details of the service principal that we have generated in step 3. (**Service Principal Id** = **clientId**, **Service Principal Key** = **clientSecret**, **Tenant ID** = **tenantId**) and click on **Verify** to make sure that the connection works.
1. Enter a user-friendly **Connection name** to use when referring to this service connection. Take note of the name because this will be required in the parameter update process.
1. Optionally, enter a **Description**.
1. Click on **Verify and save**.

    ![Connection DevOps](images/ConnectionDevOps.png)

More information can be found [here](https://docs.microsoft.com/azure/devops/pipelines/library/connect-to-azure?view=azure-devops#create-an-azure-resource-manager-service-connection-with-an-existing-service-principal).

## 2. Parameter Updates

In order to deploy the Infrastructure as Code (IaC) templates to the desired Azure subscription, you will need to modify some parameters in the forked repository. Therefore, **this step should not be skipped**. There are two files that require updates:

- `.ado/workflows/dataManagementZoneDeployment.yml` and
- `infra/params.dev.json` and

Update these files in a separate branch and then merge via Pull Request to trigger the initial deployment.

### 2.1. Configure `dataManagementZoneDeployment.yml`

To begin, please open the [.ado/workflows/dataManagementZoneDeployment.yml](/.ado/workflows/dataManagementZoneDeployment.yml). In this file you need to update the variables section. Just click on [.ado/workflows/dataManagementZoneDeployment.yml](/.ado/workflows/dataManagementZoneDeployment.yml) and edit the following section:

```yaml
variables:
  AZURE_RESOURCE_MANAGER_CONNECTION_NAME: "data-management-zone-service-connection" # Update to '{yourResourceManagerConnectionName}'
  AZURE_SUBSCRIPTION_ID: "17588eb2-2943-461a-ab3f-00a3ceac3112"                     # Update to '{yourDataManagementZoneSubscriptionId}'
  AZURE_LOCATION: "North Europe"                                                    # Update to '{yourRegionName}'
```

The following table explains each of the parameters:

| Parameter                                | Description  | Sample value |
|:-----------------------------------------|:-------------|:-------------|
| **AZURE_SUBSCRIPTION_ID**             | Specifies the subscription ID of the Data Management Zone where all the resources will be deployed | <div style="width: 36ch">`xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`</div> |
| **AZURE_LOCATION**                                 | Specifies the region where you want the resources to be deployed. Please check [Supported Regions](#supported-regions)  | `northeurope` |
| **AZURE_RESOURCE_MANAGER _CONNECTION_NAME**   | Specifies the resource manager connection name in Azure DevOps. You can leave the default value if you want to use GitHub Actions for your deployment. More details on how to create the resource manager connection in Azure DevOps can be found in step 4. b) or [here](https://docs.microsoft.com/azure/devops/pipelines/library/connect-to-azure?view=azure-devops#create-an-azure-resource-manager-service-connection-with-an-existing-service-principal). | `my-connection-name` |

### 2.2. Configure `params.dev.json`

To begin, please open the [infra/params.dev.json](/infra/params.dev.json). In this file you need to update the variable values. Just click on [infra/params.dev.json](/infra/params.dev.json) and edit the values. An explanation of the values is given in the table below:

| Parameter                                | Description  | Sample value |
|:-----------------------------------------|:-------------|:-------------|
| location | Specifies the location for all resources. | `northeurope` |
| environment | Specifies the environment of the deployment. | `dev`, `tst` or `prd` |
| prefix | Specifies the prefix for all resources created in this deployment. | `prefi` |
| vnetAddressPrefix | Specifies the address space of the vnet. | `10.0.0.0/16` |
| azureFirewallSubnetAddressPrefix | Specifies the address space of the subnet that is use for Azure Firewall. | `10.0.0.0/24` |
| servicesSubnetAddressPrefix | Specifies the address space of the subnet that is used for the services. | `10.0.1.0/24` |
| firewallPrivateIp | Specifies the private IP address of the central firewall. | `10.0.0.4` |
| dnsServerAdresses | Specifies the private IP addresses of the dns servers. | [ `10.0.0.4` ] |

## 3. Reference pipeline from GitHub repository in Azure DevOps Pipelines

### 3.1. Install Azure DevOps Pipelines GitHub Application

First you need to add and install the Azure Pipelines GitHub App to your GitHub account. To do so, execute the following steps:

1. Click on **Marketplace** in the top navigation bar on GitHub.
1. In the Marketplace, search for **Azure Pipelines**. The Azure Pipelines offering is free for anyone to use for public repositories and free for a single build queue if you're using a private repository.

    ![Install Azure Pipelines on GitHub](images/AzurePipelinesGH.png)

1. Select it and click on **Install it for free**.

    ![GitHub Template repository](images/InstallButtonGH.png)

1. If you are part of multiple **GitHub** organizations, you may need to use the **Switch billing account** dropdown to select the one into which you forked this repository.
1. You may be prompted to confirm your GitHub password to continue.
1. You may be prompted to log in to your Microsoft account. Make sure you log in with the one that is associated with your Azure DevOps account.

### 3.2. Configuring the Azure Pipelines project

As a last step, you need to create an Azure DevOps pipeline in your project based on the pipeline definition YAML file that is stored in your GitHub repository. To do so, execute the following steps:

1. Select the Azure DevOps project where you have setup your `Resource Manager Connection`.
1. Select **Pipelines** and then **New Pipeline** in order to create a new pipeline.

    ![Create Pipeline in DevOps](images/CreatePipelineDevOps.png)

1. Choose **GitHub YAML** and search for your repository (e.g. "`GitHubUserName/RepositoryName`").

    ![Choose code source in DevOps Pipeline](images/CodeDevOps.png)

1. Select your repository.
1. Click on **Existing Azure Pipelines in YAML file**
1. Select `main` as branch and `/.ado/workflows/dataHubDeployment.yml` as path.

    ![Configure Pipeline in DevOps](images/ConfigurePipelineDevOps.png)

1. Click on **Continue** and then on **Run**.

## 4. Merge these changes back to the `main` branch of your repo

After following the instructions and updating the parameters and variables in your repository in a separate branch and opening the pull request, you can merge the pull request back into the `main` branch of your repository by clicking on **Merge pull request**. Finally, you can click on **Delete branch** to clean up your repository. By doing this, you trigger the deployment workflow.

### 5. Follow the workflow deployment

**Congratulations!** You have successfully executed all steps to deploy the template into your environment through GitHub Azure DevOps.

You can navigate to the pipeline that you have created as part of step 3 and monitor it as each service is deployed. If you run into any issues, please open an issue [here](https://github.com/Azure/data-management-zone/issues).

<p align="right"> Next: <a href="./ESA-ManagementZone-CodeStructure.md">Code structure</a> > </p>

< Previous: [Prepare the deployment](./ESA-ManagementZone-PrepareDeployment.md)

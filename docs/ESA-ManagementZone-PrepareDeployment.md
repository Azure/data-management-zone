# Prepare the deployment

## 1. Create repository from a template

1. On GitHub, navigate to the main page of this repository.
1. Above the file list, click **Use this template**

    ![GitHub Template repository](images/UseThisTemplateGH.png)

1. Use the **Owner** drop-down menu and select the account you want to own the repository.

    ![Create Repository from Template](images/CreateRepoGH.png)

1. Type a name for your repository and an optional description.
1. Choose a repository visibility. For more information, see "[About repository visibility](https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/about-repository-visibility)."
1. Optionally, to include the directory structure and files from all branches in the template and not just the default branch, select **Include all branches**.
1. Click **Create repository from template**.

## 2. Setting up the required Service Principal and access

A service principal with *Contributor* role needs to be generated for authentication and authorization from GitHub or Azure DevOps to your Azure subscription. This is required to deploy resources to your environment. Just go to the Azure Portal to find the ID of your subscription. Then start the Cloud Shell or Azure CLI, login to Azure, set the Azure context and execute the following commands to generate the required credentials:

### 2.1. Create service principal - Azure CLI

```sh
# Replace {service-principal-name} and {subscription-id} with your
# Azure subscription id and any name for your service principal.
az ad sp create-for-rbac \
  --name "{service-principal-name}" \
  --role "Contributor" \
  --scopes "/subscriptions/{subscription-id}" \
  --sdk-auth
```

This will generate the following JSON output:

```json
{
  "clientId": "<GUID>",
  "clientSecret": "<GUID>",
  "subscriptionId": "<GUID>",
  "tenantId": "<GUID>",
  (...)
}
```

> **Note:** Take note of the output. It will be required for the next steps.

### 2.2. Add role assignments

For automation purposes, one more role assignments is required for this service principal.
Additional required role assignments include:

| Role Name | Description | Scope |
|:----------|:------------|:------|
| [User Access Administrator](https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#user-access-administrator) | Required to assign the managed identity of Purview to the Azure Key Vault. | <div style="width: 31ch">(Resource Scope) `/subscriptions/{{datalandingzone}subscriptionId}`</div> |

To add these role assignments, you can use the [Azure Portal](https://portal.azure.com/) or run the following commands using Azure CLI/Azure Powershell:

#### Azure CLI

```sh
# Get Service Principal Object ID
az ad sp list --display-name "{servicePrincipalName}" --query "[].{objectId:objectId}" --output tsv

# Add role assignment
# Resource Scope level assignment
az role assignment create \
  --assignee "{servicePrincipalObjectId}" \
  --role "{roleName}" \
  --scopes "{scope}"

# Resource group scope level assignment
az role assignment create \
  --assignee "{servicePrincipalObjectId}" \
  --role "{roleName}" \
  --resource-group "{resourceGroupName}"
```

#### Azure Powershell

```powershell
# Get Service Principal Object ID
$spObjectId = (Get-AzADServicePrincipal -DisplayName "{servicePrincipalName}").id

# Add role assignment
# For Resource Scope level assignment
New-AzRoleAssignment `
  -ObjectId $spObjectId `
  -RoleDefinitionName "{roleName}" `
  -Scope "{scope}"

# For Resource group scope level assignment
New-AzRoleAssignment `
  -ObjectId $spObjectId `
  -RoleDefinitionName "{roleName}" `
  -ResourceGroupName "{resourceGroupName}"
```

### 3. Resource Deployment

Now that you have set up the Service Principal, you need to choose how would you like to deploy the resources. Deployment options:

1. [GitHub Actions](#github-actions)
1. [Azure DevOps](#azure-devops)

<p align="right"> Next: <a href="./ESA-ManagementZone-DeployUsingGithubActions.md">Deploy Reference implementation using GitHub Actions</a> > </p>

<p align="right"> <a href="./ESA-ManagementZone-DeployUsingAzureDevops.md">Deploy Reference implementation using Azure DevOps</a> > </p>

< Previous: [Prerequisites](./ESA-ManagementZone-Prerequisites.md)

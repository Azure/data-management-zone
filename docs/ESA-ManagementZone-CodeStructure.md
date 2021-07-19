# Code Structure

| File/folder                   | Description                                |
| ----------------------------- | ------------------------------------------ |
| `.ado/workflows`              | Folder for ADO workflows. The `dataManagementZoneDeployment.yml` workflow shows the steps for an end-to-end deployment of the architecture. |
| `.github/workflows`           | Folder for GitHub workflows. The `dataManagementZoneDeployment.yml` workflow shows the steps for an end-to-end deployment of the architecture. |
| `code`                        | Sample password generation script that will be run in the deployment workflow for resources that require a password during the deployment. |
| `docs`                        | Resources for this README.                 |
| `infra`                       | Folder containing all the Bicep and ARM templates for each of the resources that will be deployed. |
| `CODE_OF_CONDUCT.md`          | Microsoft Open Source Code of Conduct.     |
| `LICENSE`                     | The license for the sample.                |
| `README.md`                   | This README file.                          |
| `SECURITY.md`                 | Microsoft Security README.                 |

<p align="right">
  Next: <a href="./ESA-ManagementZone-KnownIssues.md">Known Issues</a>
</p>

< Previous: [Deploy Reference implementation using Azure DevOps](./ESA-ManagementZone-DeployUsingAzureDevops.md)\
[Deploy Reference implementation using GitHub Actions](./ESA-ManagementZone-DeployUsingGithubActions.md)

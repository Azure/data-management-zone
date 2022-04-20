# Self-hosted CI/CD Agents

The Cloud-Scale Analytics Scenario (CSA) reference implementation uses a multi-layered security approach to overcome common data exfiltration risks raised by customers and builds on top of existing network security considerations provided by the [Enterprise-Scale Landing Zones reference design](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/enterprise-scale/network-topology-and-connectivity). One of the security layers in CSA is focused on the networking configuration and proposes network isolation as a security construct to reduce the attack surface and exfiltration risk within a customer tenant. The network isolation within the data platform is mainly accomplished through the usage of Private Endpoints and the blocking of public network traffic through the configuration of service specific firewalls. All these design considerations are very important from a security standpoint to overcome the much discussed data exfiltration risk. However, all of this also comes at the cost of increased complexity when Data Product teams start deploying solutions into their environments through CI/CD pipelines.

When a Data Product team wants to deploy application code to an Azure service (e.g. a Web Application configured with Private Endpoints) through the means of CI/CD pipelines and the usage of the default Microsoft-hosted or GitHub-hosted agents for Azure DevOps Pipelines or GitHub Actions, the deployment will fail as the Azure service will not be accessible by these publicly hosted virtual machines. The root cause is that agents will not be able to resolve the private IP address of the services as they are not able to leverage the DNS services in the customer environment. And even if the traffic coming from the public agent would be routed to the correct endpoint, the central firewall in the customer tenant would block the traffic. Lastly, it is most likely needless to say that opening firewall ports for such scenarios is also not a recommended pattern.

As a result, customers have to setup self-hosted agents that are connected to the corporate vnet. As these are hosted on the corporate network, the agents will be able to resolve the private IPs of the services and therefore will be able to deploy application code on services that are hosted using private endpoints. In order to simplify this setup, this doc will describe step-by-step how self-hosted agents can be deployed into an Cloud-scale Analytics environment.

As each service has its own way of setting up agents, we will split the following sections by service.

## Azure DevOps

In Azure DevOps, the most effective and cost efficient way of hosting self-hosted agents is through the usage of [Virtual Machine Scale Set Agents](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/scale-set-agents?view=azure-devops). These have the following benefits:

- Automatic de-provisioning of agent machines that are not being used to run jobs.
- Automated re-imaging of agent machines after each job.
- Automated agent updates and maintenance jobs.

For more details, please visit the [docs](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/scale-set-agents?view=azure-devops).

### Deployment

Please follow the steps below to deploy a [Linux based Virtual Machine Scale Set Agents](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/scale-set-agents?view=azure-devops) into an existing Cloud-scale Analytics Data Landing Zone or Data Management Zone:

1. Use the [Bicep templates](/docs/reference/buildagents/main.bicep), [ARM template](/docs/reference/buildagents/main.json) or the "Deploy To Azure" Button to deploy a virtual machine scale set (VMSS) into the environment. We are recommending to use the already existing `{prefix}-{environment}-mgmt` resource group and the `ServicesSubnet` for the deployment into your Data Management Zone or Data Landing Zone.

    [![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-management-zone%2Fmain%2Fdocs%2Freference%2Fbuildagents%2Fmain.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-management-zone%2Fmain%2Fdocs%2Freference%2Fbuildagents%2Fportal.json)

    **(Optional)** The VMSS defined in the IaC templates uses [ephemeral disk](https://docs.microsoft.com/en-us/azure/virtual-machines/ephemeral-os-disks). This feature is only availabe on a subset of virtual machine SKUs. All the options provided in the Azure Portal are supporting this functionality. If you want to deploy through ARM or Bicep and want to find out which SKUs are also supported, please run the following PowerShell script:

    ```powershell
    $vmSizes=Get-AzComputeResourceSku | where{$_.ResourceType -eq 'virtualMachines' -and $_.Locations.Contains('CentralUSEUAP')} 

    foreach($vmSize in $vmSizes)
    {
        foreach($capability in $vmSize.capabilities)
        {
            if($capability.Name -eq 'EphemeralOSDiskSupported' -and $capability.Value -eq 'true')
            {
                $vmSize
            }
        }
    }
    ```

2. Follow the [steps described here](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/scale-set-agents?view=azure-devops#create-the-scale-set-agent-pool) to connect the VMSS to Azure DevOps.

3. Our tests have shown that you may have to upgrade the existing instance in the VMSS by navigating to Instances > Select the Instance(s) > Upgrade. If your existing instance shows up with "Latest model" as "No" as shown in the image below, this may be required.

    ![Azure DevOps Scale Set Agent](/docs/images/AzureDevOpsScaleSetAgent.png)

4. Congratulations! You have successfully configured an Azure DevOps [Virtual Machine Scale Set Agents](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/scale-set-agents?view=azure-devops) and you are now able to deploy application code to privately hosted services.

    ![Azure DevOps Scale Set Agent Nodes](/docs/images/AzureDevOpsScaleSetAgentNodes.png)

## GitHub Actions

To deploy a GitHub self hosted agent, please [follow the steps described here](https://docs.github.com/en/actions/hosting-your-own-runners/adding-self-hosted-runners#adding-a-self-hosted-runner-to-a-repository). If you require an automated solution for the setup, please raise an issue in this GitHub repository to make us aware of it. We will consider these requests when planning our sprints.

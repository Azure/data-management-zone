# Self-hosted Agents

The Enterprise-Scale Analytics reference implementation uses a secure network design that is mainly accomplished through the usage of Private Endpoints and the blocking of public network traffic through the configuration of service specific firewalls. All this effort is done to overcome the data exfiltration risk within the customer environment. However, all of this also comes at the cost of increased difficulty when Data Product teams start deploying solutions into their environments through CI/CD pipelines.

When a Data Product team wants to deploy application code to a service (e.g. a Web Application setup with Private Endpoints) through the means of CI/CD pipelines and the usage of the default Microsoft-hosted or GitHub-hosted agents for Azure DevOps Pipelines or GitHub Actions, the deployment will fail as the service will not be accessible by these publicly hosted virtual machines. The root cause is that in such scenarios the agents will not even be able to resolve the private IP address of the services as they are not able to leverage the DNS services in the customer environment. And even if the traffic coming from the agent would be routed to the right endpoint, the central firewall in the customer environment would block the traffic and opening firewall ports for such scenarios is also not a recommended pattern.

As a result, customers have to setup self-hosted agents that are connected to the corporate vnet. As these are then hosted on the corporate network, these agents will be able to resolve the private IPs of the services and therefore will be able to deploy application code on services that are hosted using private endpoints. In order to simplify this setup, this doc will describe step-by-step how self-hosted agents can be deployed into an Enterprise-Scale Analytics environment.

As each service has its own way of setting up agents, we will split the following sections by service. 

## Azure DevOps



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

![Azure DevOps Scale Set Agent](/docs/images/AzureDevOpsScaleSetAgent.png)
# Connecting to Environments Privately

The Cloud-Scale Analytics Scenario reference architecture is secure by design and uses a multi-layered security approach to overcome common data exfiltration risks raised by customers. Features on a network, identity, data and service layer, enable customers to define granular access controls to only expose required data to a user. Even if some of these security mechanisms fail, data within the ESA platform stays secure.

Network features like private endpoints and disabled public network access greatly reduce the attack surface of a data platform of an organization. However, with these features enabled, additional steps need to be taken to successfully connect to the respective services like Storage Accounts, Synapse workspaces, Purview or Azure Machine Learning from the public internet. Therefore, this document will describe the most common options for connecting to services inside the Data Management Zone or Data Landing Zone in a simple and secure way.

## Bastion Host & Jumpbox

The most simple solution is to host a jumpbox on the virtual network of the Data Management Zone or Data Landing Zone to connect to the data services through private endpoints. The jumpbox would be an Azure Virtual Machine (VM) running Linux or Windows to which users can connect via Remote Desktp Protocol (RDP) or Secure Shell Protocol (SSH).

Previously, jumpbox VMs had to be hosted with public IPs to enable RDP and SSH sessions from the public internet. Network Security Groups (NSGs) could be used to further lock down traffic to only allow connections from a limited set of public Ips. However, this meant that a public IP needed to be exposed from the Azure environment, which again increased the attack surface of an organization. Alternatively, customers could have used DNAT rules in their Azure Firewall to expose the SSH or RDP port of a VM to the public internet, leading to similar security risks.

Today, instead of exposing a VM publicly, customers can rely on Azure Bastion as a more secure alternative. Azure Bastion provides a secure remote connection from the Azure portal to Azure VMs over Transport Layer Security (TLS). Azure Bastion needs to be provisioned to a dedicated subnet (subnet with name `AzureBastionSubnet`) in the Azure Data Landing Zone or Azure Data Management Zone and can then be used to connect to any VM on that virtual network or a peered virtual network directly from the Azure portal. No additional clients or agents need to be installed on any VM. NSGs can again be used to allow RDP and SSH from Azure Bastion only.

![Azure Bastion Network Architecture](/docs/images/AzureBastionNetworkArchitecture.png)

A few other core security benefits of Azure Bastion are:

1. The traffic initiated from Azure Bastion to the target VM stays within the customer Vnet.
2. Protection against port scanning, since RDP ports, SSH ports, and public IP addresses aren't publicly exposed for VMs.
3. Azure Bastion helps protect against zero-day exploits. It sits at the perimeter of your virtual network. So you don't need to worry about hardening each of the virtual machines in your virtual network. The Azure platform keeps Azure Bastion up to date since it is a PaaS service.
4. The service integrates with native security appliances for an Azure virtual network, like Azure Firewall.
5. Azure Bastion can be used to monitor and manage remote connections.

More details about Azure Bastion can be found [here](https://docs.microsoft.com/en-us/azure/bastion/bastion-overview).

### Deployment

To simplify the setup for Cloud-Scale Analytics Scenario users, we have been working on a Bicep/ARM template to quickly recreate this setup inside your Data Management Zone or Data Landing Zone. Our template will create the following setup inside your subscription:

![Azure Bastion Architecture](/docs/images/AzureBastionArchitecture.png)

To deploy this yourself, please use the following Deploy to Azure button:

[![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-management-zone%2Fmain%2Fdocs%2Freference%2Fbastionhost%2Fmain.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-management-zone%2Fmain%2Fdocs%2Freference%2Fbastionhost%2Fportal.json)

When deploying Azure Bastion and the jumpbox through the Deploy to Azure button, you can provide the same prefix and environment as for your Data Landing Zone or Data Management Zone. There will be no conflicts and this deployment acts as an add-on to your Data Landing or Management Zone. Additional, VMs can be added manually to allow more users to work inside the environment.

### Connecting to the VM

After the deployment, you will notice that two additional subnets have been created on the Data Landing Zone Vnet.

![Bastion And Jumpbox Subnets](/docs/images/AzureBastionSubnets.png)

In addition, you will find a new resource group inside your subscripion, which includes the Azure Bastion resource as well as a Virtual Machine:

![Bastion And Jumpbox Subnets](/docs/images/AzureBastionResourceGroup.png)

If you want to connect to the VM using Azure Bastion, execute the following steps:

1. Click on the VM (in our case `dlz01-dev-bastion`) > "Connect" > "Bastion".

    ![Connect to VM via Bastion](/docs/images/AzureBastionConnectToVm.png)

2. Click on the blue button "Use Bastion".
3. Enter your Credentials and click "Connect".

    ![Connect to VM via Bastion](/docs/images/AzureBastionEnterCredentials.png)

4. The RDP session opens in a new Tab inside your Browser and you can start connecting to your data services.
5. Once logged into the VM in a separate browser tab, go to Microsoft Edge and open [Azure Portal](https://portal.azure.com/). From here, navigate to the `{prefix}-{environment}-product-synapse001` Synapse workspace inside the `{prefix}-{environment}-shared-product` resource group for data exploration.

    ![Connect to Synapse Workspace](/docs/images/dev-shared-product-synapse.png)

6. After logging into the Synapse workspace, load a sample dataset from the gallery (e.g. NYC Taxi Dataset). Once imported, click on "New SQL Script" to query "TOP 100 rows".

    ![Connect to New SQL Script](/docs/images/new-sql-script.png)

Only a single jumpbox in one of the Data Landing Zone is required to access services across all Data Landing Zones and Data Management Zones, if all the virtual networks have been peered with each other. More details on why this this network setup is recommended can be found [here](/docs/guidance/DataManagementAnalytics-NetworkArchitecture.md). A maximum of one Azure Bastion service is recommended per Data Landing Zone. If more users require access to the environment, additional Azure VMs can be added to the Data Landing Zone.

### Conditional Access Policies: Enroll your private VM to Intune

If you are deploying your solution into a corporate tenant, you might bump into conditional access policies that enforce you to enroll your VM to Intune for it to be considered a trusted device and access your Azure resources from there. Since working in a shared Azure subscription will grant all subscription owners access to the VM, it is recommended to enroll only VMs in your private subscription to Intune. Please follow the steps below to setup an Intune enrolled Jumpbox VM in your own Azure subscription to connect to the shared Data Management Zone and Data Landing Zone Azure resources. If you are not working in a shared subscription you can safely skip the first steps and go directly to step 6. to enroll the Jumpbox VM created above to Intune.

1. Create a Vnet in your own Azure subscription, make sure that the address space does not overlap with the Vnets for the Data Management Zone `{dmz-prefix}-{environment}-vnet` or Data Landing Zone(s) `{dlz-prefix}-{environment}-vnet` in the shared Azure subscription(s);
2. Once created, go the settings pane of the new Vnet and adjust the DNS server to the a Custom one (in the default setup the Firewall is used as DNS Forwarder and the default IP address of the Firewall in the Data Management Zone is 10.0.0.4). Check the Vnet of the Data Landing Zone and apply the same settings to your new Vnet;
3. Peer the Vnet to both `{dmz-prefix}-{environment}-vnet` and `{dlz-prefix}-{environment}-vnet` in your shared Azure subscription(s);
4. Create a Windows 11 Virtual Machine (Windows 11 Pro - Gen2 image - other images might also work) in  your own Azure subscription and:
    1. Use your own private admin username and password;
    2. Close inbound ports;
    3. Make sure to place the VM inside the newly created Vnet;
5. Create a new Route Table in your own Azure subscription, with the following setup:
    1. In Settings > Routes add a route with name `default-route-to-firewall` with: Address prefix: 0.0.0.0/0, Next hop type: Virtual Appliance, Next hop address: internal IP of your Firewall (10.0.0.4 is the default internal IP of the Azure Firewall in the Data Management Zone. Please check the Route Table in your Data Landing Zone and apply the same settings).
    2. In Settings > Subnets associate the subnet where your VM is located.
6. Login to the VM via Azure Bastion with your own admin username and password;
7. On the VM, complete the following actions:
    1. Go to Settings > Accounts > Access work or school > Add a work or school account and connect your Corporate Account;
    2. Go to the Microsoft Store and sign in with your Corporate Account. Install the Company Portal app, and enroll the device to your corporate network. The app will guide you through the process;
    3. Open the Edge browser on the VM and sign in with your Corporate Account;
    4. Go to portal.azure.com and login with your Corporate Account;
8. Make sure to pause your VM when you are not using it and consider setting an auto-shutdown to prevent high costs.

## Point to Site (P2S) Connection

Another alternative to connect users to the virtual network is through the use of Point to Site (P2S) connections. An Azure native solution for this approach, requires setting up a VPN Gateway to allow Virtual Private Network (VPN) connections between users and the VPN Gateway over an encrypted tunnel. Once the connection is established, users can start connecting privately to services hosted on the virtual network inside the Azure tenant including storage accounts, Synapse and Purview.

It is recommended to setup the VPN Gateway in the Hub Vnet of the Hub & Spoke architecture. Detailed step-by-step guidance on how to setup a VPN gateway can be found [here](https://docs.microsoft.com/en-us/azure/vpn-gateway/tutorial-create-gateway-portal).

## Site to Site (S2S) Connection

If users are already connected to the on-premise network environment and connectivity should be extended to Azure, Site to Site (S2S) connections can be used to connect the on-prem and Azure Connectivity Hub. Simmilar to the VPN tunnel, the S2S connection allows to extend the connectivity to the Azure environment to allow users connected to the corporate network to connect privately to services hosted on the virtual network inside the Azure tenant including storage accounts, Synapse and Purview.

The recommended and Azure native apporach for such connectivity is the usage of ExpressRoute. It is recommended to setup the ExpressRoute Gateway in the Hub Vnet of the Hub & Spoke architecture. Detailed step-by-step guidance on how to setup ExpressRoute connectivity can be found [here](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-howto-routing-portal-resource-manager).

## More Guidance

More guidance around how to setup connectivity to Azure can be found in the [Cloud Adoption Framework](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/connectivity-to-azure).

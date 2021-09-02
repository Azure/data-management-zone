# Connecting to the Environment

The Enterprise-Scale reference architecture is secure by design and uses a multi-layered security approach to overcome common data exfiltration risks raised by customers. Features on a network, identity, data and service layer, enable customers to define granular access controls to only expose required data to a user. Even if some of these security mechanisms fail, data within the ESA platform stays secure.

Network features like private endpoints and disabled public network access greatly reduce the attack surface of a data platform of an organization. However, with these features enabled, additional steps need to be taken to successfully connect to the respective services like Storage Accounts, Synapse workspaces, Purview or Azure Machine Learning from the public internet. Therefore, this document will describe the most common options for connecting to services inside the Data Management Zone or Data Landing Zone in a simple and secure way.

## Bastion Host & Jumpbox

The most simple solution is to host a jumpbox on the virtual network of the Data Management Zone or Data Landing Zone to connect to the data services through private endpoints. The jumpbox would be an Azure Virtual Machine (VM) running Linux or Windows to which users can connect via Remote Desktp Protocol (RDP) or Secure Shell Protocol (SSH).

Previously, jumpbox VMs had to be hosted with public IPs to enable RDP and SSH sessions from the public internet. Network Security Groups (NSGs) could be used to further lock down traffic to only allow connections from a limited number of public Ips. However, this meant that a public IP needed to be exposed from the Azure environment, which again increased the attack surface of an organization. Alternatively, customers could have used DNAT rules in their Azure Firewall to expose the SSH or RDP port of a VM to the public internet, leading to similar security risks.

Today, instead of exposing a VM publicly, customers can rely on Azure Bastion as a more secure alternative. Azure Bastion provides a secure remote connection from the Azure portal to Azure VMs over Transport Layer Security (TLS). Azure Bastion needs to be provisioned to a dedicated subnet (subnet with name `AzureBastionSubnet`) in the Azure Data Landing Zone or Azure Data Management Zone and can then be used to connect to any VM on that virtual network or a peered virtual network directly from the Azure portal. No additional clients or agents need to be installed on any VM. NSGs can again be used to allow RDP and SSH from Azure Bastion only. 

![Azure Bastion Architecture](AzureBastionArchitecture.png)

A few other core security benefits of Azure Bastion are:

1. The traffic initiated from Azure Bastion to the target VM stays within the customer Vnet.
2. Protection against port scanning, since RDP ports, SSH ports, and public IP addresses aren't publicly exposed for VMs.
3. Azure Bastion helps protect against zero-day exploits. It sits at the perimeter of your virtual network. So you don't need to worry about hardening each of the virtual machines in your virtual network. The Azure platform keeps Azure Bastion up to date since it is a PaaS service.
4. The service integrates with native security appliances for an Azure virtual network, like Azure Firewall.
5. Azure Bastion can be used to monitor and manage remote connections.

To deploy a jumpbox and Azure Bastion to your Data Management Zone or Data Landing Zone, you can use the following Deploy to Azure Button:

[![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-management-zone%2Fmain%2Fdocs%2Freference%2Fbastionhost%2Fmain.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-product-batch%2Fmain%2Fdocs%2Freference%2Fportal.dataProduct.json)

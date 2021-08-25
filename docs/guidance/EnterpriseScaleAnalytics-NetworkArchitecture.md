# Network Architecture Considerations

Enterprise-Scale Analytics promises the possibility to easily share and access datasets across multiple data domains and Data Landing Zones without critical bandwith limitations and without creating multiple copies of the same dataset. To deliver on that promise, different network designs were considered, evaluated and tested. Based on the current capabilities of Azure Networking Services it is recommended to rely on a meshed network architecture. What this means is that it is recommended to setup vnet peering between

1. The Connectivity Hub and Data Management Zone,
2. The Connectivity Hub and each Data Landing Zone,
3. The Data Management Zone and each Data Landing Zone and
4. Each Data Landing Zone.

![Meshed Network Architecture](/docs/images/NetworkOptions-NetworkMesh.png)

To explain the rational behind the recommended design, this article will illustrate the advantages and disadvantages that come with each of the different network architecture approaches that were considered when designing Enterprise-Scale Analytics. Every design pattern will be evaluated along the following criteria: Cost, User Access Management, Service Management and Bandwith. Each scenario will be analyzed with the following cross-Data Landing Zone use-case in mind: 

---

_Virtual machine B (VM B) hosted in Data Landing Zone B loads a dataset from Storage Account A hosted in Data Landing Zone A. Next, it processes the dataset and finally it stores the processed dataset and finally stores the processed dataset in Storage Account B hosted in Data Landing Zone B._

---

## Option 1: Traditional Hub & Spoke Design

The most obvious option would be to leverage the traditional Hub & Spoke network architecture that many enterprises have adopted. Network transitivity would have to be setup in the Connectivity Hub in order to be able to access data in Storage Account A from VM B. Data would traverse two vnet peerings ((2) and (5)) as well as a Network Virtual Appliance (NVA) hosted inside the Connectivity Hub ((3) and (4)) before it gets gets loaded by the virtual machine (6). 

![Hub and Spoke Architecture](/docs/images/NetworkOptions-HubAndSpoke.png)


### User Access Management

With this solution approach Data Product teams will only require write access to the respective resource group in the Data Landing Zone as well as join access to their designated subnet to be able to create new services including the private endpoints in a self-service manner. Therefore, Data Product teams can deploy private endpoints themselves and don't require support to setup the necessary connectivity if they get the access rights provided to connect private endpoints to a subnet in that Spoke.

Summary: :heavy_plus_sign::heavy_plus_sign::heavy_plus_sign:

### Service Management

The most relevant benefit of this network architecture design is that it is in line with the existing network setup of most customers. Therefore, it is easy to explain and implement. In addition, a centralized and Azure native DNS solution with Private DNS Zones can be used to provide FQDN resolution inside the Azure tenant. The use of Private DNS Zones also allows for the automation of the DNS A-record lifecycle through [Azure Policies](/infra/Policies/PolicyDefinitions/PrivateDnsZoneGroups/). Since tarffic is routed through a central NVA, network traffic that is sent from one Spoke to another one can also be logged and inspected, which can be another benefit of this design.

A downside of this solution from a service management perspective is that the central Azure Platform team must manage Route Tables manually. This is required to ensure the necessary transitivity between Spokes to enable the process of sharing data assets across multiple Data Landing Zones. The management of routes can become complex and error prone over time and is something that should be considered upfront. The more critical disadvantage of this network setup is the central NVA. Firstly, the NVA acts as a single point of failure and can cause serius downtime inside the data platform in case of a failure. Secondly, as the dataset sizes grow inside the data platform and as the cross Data Landing Zone use cases grow more and more traffic will be sent through the central NVA. Over time, this can result in gigabytes or terabytes of data that is sent through the central instance. However, the bandwith of existing NVAs is often limited to a one- or two-digit gigabyte bandwith. Therefore, the appliance can act as a critical bottleneck limiting the traffic flowing between Data Landing Zones and therefore limiting the shareability of data assets. The only way to overcome this issue would be to scale out the central NVA across multiple instances, which will have huge implications on cost of this solution.

Summary: :heavy_minus_sign:

### Cost

---

_When accessing a private endpoint across a peered network customers will only ever be charged for the private Endpoint itself and not for the Vnet peering. The official statement can be found [here (FAQ: How will billing work when accessing a private endpoint from a peered network?)](https://azure.microsoft.com/en-us/pricing/details/private-link/)._

---

From a network perspective, customers have to pay for the two private endpoints of the Storage Accounts (charged per hour) as well as the ingress and egress traffic that is sent through the private endpoints to load the raw (1) and store the processed dataset (8). In addition, the customer will be charged for the ingress and egress of one Vnet peering (5). Due to the statement above, the other Vnet pering will not be charged (2). Lastly, customers will end up with very significant cost for the central NVA when choosing this network design ((3) and (4)). The high cost will be generated either because additional licenses need to be purchased to scale out based on demand or it will be generated because of the charge per processed gigabyte as it is done with Azure Firewall.

Summary: :heavy_minus_sign::heavy_minus_sign::heavy_minus_sign:

### Bandwith

This network design has serius limitations from a bandwith perspective. The central NVA will become a critical bottleneck as the platform grows, which will limit cross Data Landing Zone use cases and sharing of datsets and most likely lead to a situation where multiple copies of datasets will be created over time.

Summary: :heavy_minus_sign::heavy_minus_sign::heavy_minus_sign:

### Summary

From an access management and partially from a service management perspective, this setup has benefits. But due to the critical limitations pointed out in the service management, cost and bandwith section, this network design cannot be recommended for cross Data Landing Zone use cases.

## Option 2: Private Endpoint Projection

Another design alternative that was evaluated was the projection of private endpoints across each and every Landing Zone. With this approach, a private endpoint for Storage Account A would be created each Data Landing Zone. Therefore, this option leads to a first private endpoint in Data Landing Zone A that is connected to to the Vnet in Data Landing Zone A, a second private private endpoint in Data Landing Zone B that is connected to to the Vnet in Data Landing Zone B, etc. The same applies to Storage Account B and potentially other services inside the Data Landing Zones. If the number of Data Landing Zones is defined as _n_, one would end up with _n_ private endpoints for at least all of the storage accounts and potentially other services within the Data Landing Zones.

![Private Endpoint Projection Architecture](/docs/images/NetworkOptions-PrivateEndpointProjection.png)

Since all private endpoints of a particular service (e.g. Storage Account A) have the same FQDN (e.g. `storageaccounta.privatelink.blob.core.windows.net`) this solution creates challenges on the DNS layer which cannot be solved with Private DNS Zones. A custom DNS solution is required that is capable of resolving DNS names based on the origin/IP of the requestor in order to make VM A connect to the Private Endpoints connected to the Vnet in Data Landing Zone A and make VM B connect to the Private Endpoints connected to the Vnet in Data Landing Zone B. This can be done with a setup based on Windows Servers, whereas the lifecycle of DNS A-records can be automated through a combination of Activity Log and Azure Functions.

### User Access Management

From a user access maangement perspective this scenario is very similar to the first option except for the fact that access rights may also be required for other Data Landing Zones to not just create private endpoints within the designated Data Landing Zone and Vnet but also in the other Data Landing Zones and their respective Vnets. Hence, Data Product teams may not only require  write access to the respective resource group in the designated Data Landing Zone as well as join access to their designated subnet to be able to create new services including the private endpoints in a self-service manner, but they may also require access to a resource group and subnet inside the other Data Landing Zones to create the respective local private endpoints. In summary, this setup increases the complexity on the acces management layer since Data Product teams may require few permissions in each and every Data Landing Zone. In addition, it may lead to confusion and inconsistent RBAC over time. If required access rights are not provided to Data Landing Zone teams or Data Product teams, problems described in [Option 1: Traditional Hub & Spoke Design]() will be applicable.

Summary: :heavy_minus_sign:

### Service Management

Option 2 has the benefit that there is no NVA acting as a single point of failure or throttling throughput. Not sending the datasets through the Connectivity Hub also reduces the management overhead for the central Azure platform team, as there is no need for scaling out the virtual appliance. This has the implication that the central Azure platform team can no longer inspect and log all traffic that is sent between Data Landing Zones. Nonetheless, this is not seen as disadvantage since Enterprise-Scale Analytics can be considered as coherent platform that spans across multiple subscriptions to allow for scale and overcome platform level limitations. If all resources would be hosted inside a single subscription, traffic would also not be inspected in the central Connectivity Hub. In addition, network logs can still be captured through the use of Network Security Group Flow Logs and additional application and service level logs can be consolidated and stored through the use of service specific Diagnostic Settings. All of these logs can be captured at scale through the use of [Azure Policies](/infra/Policies/PolicyDefinitions/DiagnosticSettings/).

On ther other hand, the exponential growth of the number of required Private Endpoints also increases the network address space required by the data platform, which is not optimal. Lastly, the above mentioned DNS challenges are the biggest concern of this network architecture. An Azure native solution in the form of Private DNS Zones cannot be used. Hence, a third party solution will be required that is capable of resolving FQDNS based on the IP/origin of the requestor. In addition, tools must be developed to manage the lifecycle of Private DNS A-records which drastically increases the management overhead compared to the proposed [Azure Policy driven solution](/infra/Policies/PolicyDefinitions/PrivateDnsZoneGroups/). It would also be possible to create a distributed DNS infrastructure using Private DNS Zones, but with this solution we would create DNS islands which ultimately would lead to issues when trying to access services within other Landing Zones within the tenant. Therefore, this is not a viable alternative.

Summary: :heavy_minus_sign::heavy_minus_sign::heavy_minus_sign:

### Cost

---

_When accessing a private endpoint across a peered network customers will only ever be charged for the private Endpoint itself and not for the Vnet peering. The official statement can be found [here (FAQ: How will billing work when accessing a private endpoint from a peered network?)](https://azure.microsoft.com/en-us/pricing/details/private-link/)._

---

With this network design, customers only pay for the private endpoints (charged per hour) as well as the ingress and egress traffic that is sent through the private endpoints to load the raw (1) and store the processed dataset (4). However, due to the exponential growth of the number of private endpoints inside the data platform additional costs must be expected and will highly depend on the number of private endpoints that are created since these are charged per hour. 

Summary: :heavy_plus_sign:

### Bandwith

Due to the fact that there are no NVAs limiting throughput for cross Data Landing Zone data exchange, there are no known limitatons from a bandwith perspective. Physical limits in our datacenters are the only limiting factor (speed of fiber cables/light). 

Summary: :heavy_plus_sign::heavy_plus_sign::heavy_plus_sign:

### Summary

This network architecture suffers from the potential exponential growth of private endpoints which may even cause loosing track of which private endpoints are used where and for which purpose. Another limiting factor are the access management issues described above as well as the complexities created on the DNS layer. Therfore, in summary, this network design cannot be recommended.

## Option 3: Private Endpoint in Connectivity Hub

### User Access Management

Summary: 

### Service Management

Summary: 

### Cost

---

_When accessing a private endpoint across a peered network customers will only ever be charged for the private Endpoint itself and not for the Vnet peering. The official statement can be found [here (FAQ: How will billing work when accessing a private endpoint from a peered network?)](https://azure.microsoft.com/en-us/pricing/details/private-link/)._

---

Summary: 

### Bandwith

Summary: 

### Summary


## Option 4: Meshed Network Architecture

### User Access Management

Summary: 

### Service Management

Summary: 

### Cost

---

_When accessing a private endpoint across a peered network customers will only ever be charged for the private Endpoint itself and not for the Vnet peering. The official statement can be found [here (FAQ: How will billing work when accessing a private endpoint from a peered network?)](https://azure.microsoft.com/en-us/pricing/details/private-link/)._

---

Summary: 

### Bandwith

Summary: 

### Summary

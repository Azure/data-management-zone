# Network Architecture Considerations

The Data Management and Analytics Scenario promises the possibility to easily share and access datasets across multiple data domains and Data Landing Zones without critical bandwidth or latency limitations and without creating multiple copies of the same dataset. To deliver on that promise, different network designs had to be considered, evaluated and tested to make sure that these are compatible with the existing Hub and Spoke and vWAN deployments of corporations. Based on the current capabilities of Azure Networking Services it is recommended to rely on a meshed network architecture. What this means is that it is recommended to setup Vnet peering between

1. The Connectivity Hub and Data Management Zone,
2. The Connectivity Hub and each Data Landing Zone,
3. The Data Management Zone and each Data Landing Zone and
4. Each Data Landing Zone.

![Meshed Network Architecture](/docs/images/NetworkOptions-NetworkMesh.png)

To explain the rationale behind the recommended design, this article will illustrate the advantages and disadvantages that come with each of the different network architecture approaches that were considered when designing the Data Management and Analytics Scenario. The first section of this article will only look at a single-region pattern, where the Data Management Zone as well as all the Data Landing Zones are hosted in the same region. The second chapter will specifically focus on the cross-region setup and will provide recommendations for such data access patterns.

## Single-region Data Landing Zone Connectivity

![Single-region Data Landing Zone Connectivity](/docs/images/SingleRegionConnectivity.png)

In the single-region setup, the Data Management Zone, the Data Landing Zones as well as all the services within them are setup in the same region. Also, all Landing Zones are connected to the same connectivity hub subscription, where shared network resources including an NVA like an Azure Firewall, an ExpressRoute Gateway, a VPN Gateway, the Hub Virtual Network in case of a Hub&Spoke architecture or the vWAN Hub in case of a vWan setup are hosted.

Every considered design pattern will now be evaluated along the following criteria: Cost, User Access Management, Service Management and Bandwidth & Latency. Each scenario will be analyzed with the following cross-Data Landing Zone use-case in mind:

---

_Virtual machine B (VM B) hosted in Data Landing Zone B loads a dataset from Storage Account A hosted in Data Landing Zone A. Next, it processes the dataset and finally it stores the processed dataset and in Storage Account B hosted in Data Landing Zone B._

---

### 1. Meshed Network Architecture (Recommended)

The recommended design proposes the use of a network mesh, which means adding Vnet peerings between all Data Landing Zone Vnets and between the Data Management Zone and each Data Landing Zone in addition to the existing Hub and Spoke network design that most organizations have setup inside their tenant. For the scenario mentioned in the introduction, data loaded from Storage Account A would first transition a Vnet peering connection (2) that is setup between the two Data Landing Zone Vnets before it would be loaded and processed by VM B ((3) and (4)). Lastly, the data can be stored on Storage Account B by sending the data through the local Private Endpoint (5). With this option, the data does not pass the Connectivity Hub and stays within the Data Platform consisting of a Data Management Zones and one or multiple Data Landing Zones.

![Meshed Network Architecture](/docs/images/NetworkOptions-MeshedNetworkArchitecture.png)

#### User Access Management

With this solution approach Data Product teams will only require write access to their dedicated resource group in the Data Landing Zone as well as join access to their designated subnet to be able to create new services including the Private Endpoints in a self-service manner. Therefore, Data Product teams can deploy Private Endpoints themselves and don't require support to setup the necessary connectivity if they get the necessary access rights provided to connect Private Endpoints to a subnet in that Spoke.

Summary: :heavy_plus_sign::heavy_plus_sign::heavy_plus_sign:

#### Service Management

This network design has the benefit that there is no NVA acting as a single point of failure or throttling throughput. Not sending the datasets through the Connectivity Hub also reduces the management overhead for the central Azure platform team, as there is no need for scaling out the virtual appliance. This has the implication that the central Azure platform team can no longer inspect and log all traffic that is sent between Data Landing Zones. Nonetheless, this is not seen as disadvantage since the Data Management and Analytics Scenario can be considered as coherent platform that spans across multiple subscriptions to allow for scale and overcome platform level limitations. If all resources would be hosted inside a single subscription, traffic would also not be inspected in the central Connectivity Hub. In addition, network logs can still be captured through the use of Network Security Group Flow Logs and additional application and service level logs can be consolidated and stored through the use of service specific Diagnostic Settings. All of these logs can be captured at scale through the use of [Azure Policies](/infra/Policies/PolicyDefinitions/DiagnosticSettings/). Also, this pattern allows for an Azure native DNS solution based on Private DNS Zones and allows for the automation of the DNS A-record lifecycle through [Azure Policies](/infra/Policies/PolicyDefinitions/PrivateDnsZoneGroups/).

Summary: :heavy_plus_sign::heavy_plus_sign::heavy_plus_sign:

#### Cost

---

_When accessing a Private Endpoint across a peered network customers will only ever be charged for the private Endpoint itself and not for the Vnet peering. The official statement can be found [here (FAQ: How will billing work when accessing a Private Endpoint from a peered network?)](https://azure.microsoft.com/en-us/pricing/details/private-link/)._

---

With this network design, customers only pay for the Private Endpoints (charged per hour) as well as the ingress and egress traffic that is sent through the Private Endpoints to load the raw (1) and store the processed dataset (6). Due to the statement above, the Vnet peering will not be charged (2), which is why we end up with minimal cost with this option.

Summary: :heavy_plus_sign::heavy_plus_sign::heavy_plus_sign:

#### Bandwidth and Latency

Due to the fact that there are no NVAs limiting throughput for cross-Data Landing Zone data exchange, there are no known limitations from a bandwidth and latency perspective. Physical limits in our datacenters are the only limiting factor (speed of fibre cables/light).

Summary: :heavy_plus_sign::heavy_plus_sign::heavy_plus_sign:

#### Summary

The meshed network design offers maximum bandwidth and low latency at minimal cost without any compromises from a user access management perspective or on the DNS layer. Hence, this network architecture design is the recommended for customers wanting to adopt the Data Management and Analytics Scenario. If additional network policies need to be enforced within the Data Platform, it is advised to use Network Security Groups instead of central NVAs.

### 2. Traditional Hub & Spoke Design (NOT Recommended)

The most obvious option is to leverage the traditional Hub & Spoke network architecture that many enterprises have adopted. Network transitivity would have to be setup in the Connectivity Hub in order to be able to access data in Storage Account A from VM B. Data would traverse two Vnet peerings ((2) and (5)) as well as a Network Virtual Appliance (NVA) hosted inside the Connectivity Hub ((3) and (4)) before it gets loaded by the virtual machine (6) and then stored back into the Storage Account B (8).

![Hub and Spoke Architecture](/docs/images/NetworkOptions-HubAndSpoke.png)

#### User Access Management

With this solution approach, Data Product teams will only require write access to a resource group in the respective Data Landing Zone as well as join access to their designated subnet to be able to create new services including the Private Endpoints in a self-service manner. Therefore, Data Product teams can deploy Private Endpoints themselves and don't require support to setup the necessary connectivity given that they get the necessary access rights to connect Private Endpoints to a subnet in that Spoke.

Summary: :heavy_plus_sign::heavy_plus_sign::heavy_plus_sign:

#### Service Management

The most relevant benefit of this network architecture design is that it is well-known and consistent with the existing network setup of most organizations. Therefore, it is easy to explain and implement. In addition, a centralized and Azure native DNS solution with Private DNS Zones can be used to provide FQDN resolution inside the Azure tenant. The use of Private DNS Zones also allows for the automation of the DNS A-record lifecycle through [Azure Policies](/infra/Policies/PolicyDefinitions/PrivateDnsZoneGroups/). Since traffic is routed through a central NVA, network traffic that is sent from one Spoke to another one can also be logged and inspected, which can be another benefit of this design.

A downside of this solution from a service management perspective is that the central Azure Platform team must manage Route Tables manually. This is required to ensure the necessary transitivity between Spokes to enable the process of sharing data assets across multiple Data Landing Zones. The management of routes can become complex and error-prone over time and is something that should be considered upfront. The more critical disadvantage of this network setup is the central NVA. Firstly, the NVA acts as a single point of failure and can cause serious downtime inside the data platform in case of a failure. Secondly, as the dataset sizes grow inside the data platform and as the number of cross-Data Landing Zone use cases increases more and more traffic will be sent through the central NVA. Over time, this can result in gigabytes or terabytes of data that is sent through the central instance. However, the bandwidth of existing NVAs is often limited to a one- or two-digit gigabyte throughput. Therefore, the appliance can act as a critical bottleneck limiting the traffic flowing between Data Landing Zones and therefore limiting the shareability of data assets. The only way to overcome this issue would be to scale out the central NVA across multiple instances, which will have huge implications on cost of this solution.

Summary: :heavy_minus_sign:

#### Cost

---

_When accessing a Private Endpoint across a peered network customers will only ever be charged for the private Endpoint itself and not for the Vnet peering. The official statement can be found [here (FAQ: How will billing work when accessing a Private Endpoint from a peered network?)](https://azure.microsoft.com/en-us/pricing/details/private-link/)._

---

From a network perspective, customers have to pay for the two Private Endpoints of the Storage Accounts (charged per hour) as well as the ingress and egress traffic that is sent through the Private Endpoints to load the raw (1) and store the processed dataset (8). In addition, the customer will be charged for the ingress and egress of one Vnet peering (5). Due to the statement above, the first Vnet peering will not be charged (2). Lastly, customers will end up with very significant cost for the central NVA when choosing this network design ((3) and (4)). The high cost will be generated either because additional licenses need to be purchased to scale out based on demand or it will be generated because of the charge per processed gigabyte as it is done with Azure Firewall.

Summary: :heavy_minus_sign::heavy_minus_sign::heavy_minus_sign:

#### Bandwidth & Latency

This network design has serious limitations from a bandwidth perspective. The central NVA will become a critical bottleneck as the platform grows, which will limit cross-Data Landing Zone use cases and sharing of datasets and most likely lead to a situation where multiple copies of datasets will be created over time. In addition to bandwidth, latency will be heavily impacted by that network design, which is especially critical for real-time analytics scenarios.

Summary: :heavy_minus_sign::heavy_minus_sign::heavy_minus_sign:

#### Summary

From an access management and partially from a service management perspective, this setup has benefits. But due to the critical limitations pointed out in the service management, cost and bandwidth & latency section, this network design cannot be recommended for cross-Data Landing Zone use cases.

### 3. Private Endpoint Projection (NOT Recommended)

Another design alternative that was evaluated was the projection of Private Endpoints across each and every Landing Zone. With this approach, a Private Endpoint for Storage Account A would be created each Data Landing Zone. Therefore, this option leads to a first Private Endpoint in Data Landing Zone A that is connected to the Vnet in Data Landing Zone A, a second Private Endpoint in Data Landing Zone B that is connected to the Vnet in Data Landing Zone B, etc. The same applies to Storage Account B and potentially other services inside the Data Landing Zones. If the number of Data Landing Zones is defined as _n_, one would end up with _n_ Private Endpoints for at least all of the storage accounts and potentially other services within the Data Landing Zones leading to an exponential growth of the number of Private Endpoints.

![Private Endpoint Projection Architecture](/docs/images/NetworkOptions-PrivateEndpointProjection.png)

Since all Private Endpoints of a particular service (e.g. Storage Account A) have the same FQDN (e.g. `storageaccounta.privatelink.blob.core.windows.net`) this solution creates challenges on the DNS layer which cannot be solved with Private DNS Zones. A custom DNS solution is required that is capable of resolving DNS names based on the origin/IP-address of the requestor in order to make VM A connect to the Private Endpoints connected to the Vnet in Data Landing Zone A and make VM B connect to the Private Endpoints connected to the Vnet in Data Landing Zone B. This can be done with a setup based on Windows Servers, whereas the lifecycle of DNS A-records can be automated through a combination of Activity Log and Azure Functions.

With this setup, VM B can load the raw dataset in Storage Account A by accessing it through the local Private Endpoint (1). After the dataset has been loaded and processed ((2) and (3)) the dataset can be stored on Storage Account B by directly accessing the local Private Endpoint (4). Data must not traverse any Vnet peerings within this scenario.

#### User Access Management

From a user access management perspective, this scenario is very similar to the first option except for the fact that access rights may also be required for other Data Landing Zones to not just create Private Endpoints within the designated Data Landing Zone and Vnet but also in the other Data Landing Zones and their respective Vnets. Hence, Data Product teams may not only require write access to a resource group in the designated Data Landing Zone as well as join access to their designated subnet to be able to create new services including the Private Endpoints in a self-service manner, but they may also require access to a resource group and subnet inside the other Data Landing Zones to create the respective local Private Endpoints. In summary, this setup increases the complexity on the access management layer since Data Product teams may require few permissions not just in a single but in each and every Data Landing Zone. In addition, it may lead to confusion and inconsistent RBAC over time. If required access rights are not provided to Data Landing Zone teams or Data Product teams, problems described in [Option 2: Traditional Hub & Spoke Design](#2-traditional-hub--spoke-design-not-recommended) will be applicable.

Summary: :heavy_minus_sign:

#### Service Management

Similar to [Option 1](#1-meshed-network-architecture-recommended),this network design has the benefit that there is no NVA acting as a single point of failure or throttling throughput. Not sending the datasets through the Connectivity Hub also reduces the management overhead for the central Azure platform team, as there is no need for scaling out the virtual appliance. This has the implication that the central Azure platform team can no longer inspect and log all traffic that is sent between Data Landing Zones. Nonetheless, this is not seen as disadvantage since the Data Management and Analytics Scenario can be considered as coherent platform that spans across multiple subscriptions to allow for scale and overcome platform level limitations. If all resources would be hosted inside a single subscription, traffic would also not be inspected in the central Connectivity Hub. In addition, network logs can still be captured through the use of Network Security Group Flow Logs and additional application and service level logs can be consolidated and stored through the use of service specific Diagnostic Settings. All of these logs can be captured at scale through the use of [Azure Policies](/infra/Policies/PolicyDefinitions/DiagnosticSettings/).

On the other hand, the exponential growth of the number of required Private Endpoints also increases the network address space required by the data platform, which is not optimal. Lastly, the above-mentioned DNS challenges are the biggest concern of this network architecture. An Azure native solution in the form of Private DNS Zones cannot be used. Hence, a third-party solution will be required that is capable of resolving FQDNS based on the origin/IP-address of the requestor. In addition, tools and workflows must be developed and maintained to automate the lifecycle of Private DNS A-records which drastically increases the management overhead compared to the proposed [Azure Policy driven solution](/infra/Policies/PolicyDefinitions/PrivateDnsZoneGroups/). It would also be possible to create a distributed DNS infrastructure using Private DNS Zones, but with this solution DNS islands would be created which ultimately lead to issues when trying to access private link services hosted other Landing Zones within the tenant. Therefore, this is not a viable alternative.

Summary: :heavy_minus_sign::heavy_minus_sign::heavy_minus_sign:

#### Cost

---

_When accessing a Private Endpoint across a peered network customers will only ever be charged for the private Endpoint itself and not for the Vnet peering. The official statement can be found [here (FAQ: How will billing work when accessing a Private Endpoint from a peered network?)](https://azure.microsoft.com/en-us/pricing/details/private-link/)._

---

With this network design, customers only pay for the Private Endpoints (charged per hour) as well as the ingress and egress traffic that is sent through the Private Endpoints to load the raw (1) and store the processed dataset (4). However, due to the exponential growth of the number of Private Endpoints inside the data platform additional costs must be expected and will highly depend on the number of Private Endpoints that are created since these are charged per hour.

Summary: :heavy_plus_sign:

#### Bandwidth and Latency

Due to the fact that there are no NVAs limiting throughput for cross-Data Landing Zone data exchange, there are no known limitations from a bandwidth and latency perspective. Physical limits in our datacenters are the only limiting factor (speed of fibre cables/light).

Summary: :heavy_plus_sign::heavy_plus_sign::heavy_plus_sign:

#### Summary

This network architecture suffers from the potential exponential growth of Private Endpoints which may even cause losing track of which Private Endpoints are used where and for which purpose. Another limiting factor are the access management issues described above as well as the complexities created on the DNS layer. Therefore, this network design cannot be recommended.

### 4. Private Endpoints in Connectivity Hub (NOT Recommended)

The fourth option proposes to host the Private Endpoints in the Connectivity Hub and connect them to the Hub Vnet. With this solution, a single Private Endpoint for each service would be hosted on the corporate Vnet. Transitivity would also not be required due to the existing Hub and Spoke network architecture at most corporations and the fact that the Private Endpoints would be hosted in the Connectivity Hub with this solution. The Vnet peering between the Connectivity Hub and Data Landing Zones allow for a direct access.

In order to load a dataset stored in Storage Account A in VM B, data would have to traverse a single Vnet peering between the Connectivity Hub and the Data Landing Zone (5). Once the dataset has been loaded and processed ((3) and (4)) the dataset must traverse the Vnet peering a second time (5) before it can be stored on Storage Account B by accessing the Private Endpoint connected to the Hub Vnet (6).

![Private Endpoints in Connectivity Hub](/docs/images/NetworkOptions-PrivateEndpointsInConnectivityHub.png)

#### User Access Management

When opting for this network design, Data Landing Zone teams and Data Product teams must be given write permissions to a resource group in the Connectivity Hub subscription as well as join permissions to the Hub Vnet to be able to connect Private Endpoints to the Hub Vnet. This is not in line with the Enterprise-Scale Landing Zone base principles, since the Connectivity Hub is a subscription that is designated for the Azure platform team of an organization and is dedicated for hosting the necessary and shared network infrastructure of an organization, including Firewalls, gateways and network management tools. This network option would make the design inconsistent since access management principles are not followed and therefore this design alternative is something that most Azure platform teams will not approve.

Summary: :heavy_minus_sign::heavy_minus_sign::heavy_minus_sign:

#### Service Management

Similar to [Option 1](#1-meshed-network-architecture-recommended), this network design has the benefit that there is no NVA acting as a single point of failure or throttling throughput. Not sending the datasets through the Connectivity Hub also reduces the management overhead for the central Azure platform team, as there is no need for scaling out the virtual appliance. This has the implication that the central Azure platform team can no longer inspect and log all traffic that is sent between Data Landing Zones. Nonetheless, this is not seen as disadvantage since the Data Management and Analytics Scenario can be considered as coherent platform that spans across multiple subscriptions to allow for scale and overcome platform level limitations. If all resources would be hosted inside a single subscription, traffic would also not be inspected in the central Connectivity Hub. In addition, network logs can still be captured through the use of Network Security Group Flow Logs and additional application and service level logs can be consolidated and stored through the use of service specific Diagnostic Settings. All of these logs can be captured at scale through the use of [Azure Policies](/infra/Policies/PolicyDefinitions/DiagnosticSettings/). Also, this pattern allows for an Azure native DNS solution based on Private DNS Zones and allows for the automation of the DNS A-record lifecycle through [Azure Policies](/infra/Policies/PolicyDefinitions/PrivateDnsZoneGroups/).

Summary: :heavy_plus_sign::heavy_plus_sign::heavy_plus_sign:

#### Cost

---

_When accessing a Private Endpoint across a peered network customers will only ever be charged for the private Endpoint itself and not for the Vnet peering. The official statement can be found [here (FAQ: How will billing work when accessing a Private Endpoint from a peered network?)](https://azure.microsoft.com/en-us/pricing/details/private-link/)._

---

With this network design, customers only pay for the Private Endpoints (charged per hour) as well as the ingress and egress traffic that is sent through the Private Endpoints to load the raw (1) and store the processed dataset (6).

Summary: :heavy_plus_sign::heavy_plus_sign::heavy_plus_sign:

#### Bandwidth and Latency

Due to the fact that there are no NVAs limiting throughput for cross-Data Landing Zone data exchange, there are no known limitations from a bandwidth and latency perspective. Physical limits in our datacenters are the only limiting factor (speed of fibre cables/light).

Summary: :heavy_plus_sign::heavy_plus_sign::heavy_plus_sign:

#### Summary

There are many benefits that come with this network architecture design. However, the above-mentioned inconsistencies from an access management perspectives make the design subpar and consequently the approach does not qualify as a recommended design.

### Conclusion - Single-region Data Landing Zone Connectivity

After reviewing all network architecture options from various angles and identifying pros and cons of each proposed pattern, [Option 1](#1-meshed-network-architecture-recommended) is the clear winner. Not only from a throughput perspective, but also from a cost and management perspective the solution has tremendous benefits and therefore should be used when deploying the Data Management and Analytics Scenario. Peering spoke Virtual Networks has not been common in the past, but not doing so has also led to various issues when starting to share datasets across domains and business units. In addition, one can also argue that the Data Management and Analytics Scenario can be seen as coherent solution that just spans across multiple subscriptions. In a single subscription setup, the network traffic flow would be equal to the flow in the meshed network architecture, with the difference that within a single subsciption users will most likely hit [subscription level limits and quotas](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits) of the platform, which is something that the Data Management and Analytics Scenario wants to protect against.

## Cross-region Data Landing Zone Connectivity

![Cross-region Data Landing Zone Connectivity](/docs/images/CrossRegionConnectivity.png)

If customers have a presence in more than a single Azure region and want to host their data platform and data applications across multiple geographies, the connectivity becomes slightly more complicated.

Customers with a multi-region setup generally have a connectivity hub subscription in each of the individual Azure locations. For instance, if services are running in East US and West Europe, a connectivity hub subscription with shared network resources would exist in both regions. Shared network resources include services like an NVA such as an Azure Firewall, an ExpressRoute Gateway, a VPN Gateway, the Hub Virtual Network in case of a Hub&Spoke architecture or the vWAN Hub in case of a vWan setup.

In a Hub&Spoke architecture the hub virtual networks of these connectivity Hubs are often connected using Global Vnet peering. Another alternative that is very common in larger environments is the use of ExpressRoute Global Reach. Using either of these connectivity options, customers can achieve global routing and connectivity between spoke networks across multiple geographies and hence will also be able to move data across regions, given that the traffic does not get blocked in either of the connectivity subscriptions through the use of NVAs, NSGs and Route Tables.

### 1. Global Vnet Peering (Recommended)

The first option relies on direct global Vnet peering to connect Data Landing Zones across regions. With such a setup, the virtual machine in West Europe would access the private endpoint of the storage account in East US directly without relying on any Hub&Spoke or vWAN network architectures. Data would be directly loaded by the virtual machine over the private endpoint, would then be processed before it gets stored back on the storage account in West Europe.

#### User Access Management

There are no particular pros or cons that are related to any of the proposed options for cross-region Data Landing Zone connectivity.

Summary: :heavy_plus_sign:/:heavy_minus_sign:

#### Service Management

With this network design, there is no NVA in between acting as a single point of failure or throttling throughput. By not sending the data through the connectivity hubs, the management overhead for the core Azure platform team will also be reduced, as there will be no need to scale the virtual appliances and gateways in the connectivity hubs. In addition, the need for allow-listing individual cross-region connections will be omitted. Data team swill no longer have to wait for route table changes in order to be able to access data from another Data Landing Zone in another region.

This network design change also has the impact that the platform team can no longer inspect and log all traffic using a layer 7 firewall. However, this is not considered as disadvantage as Data Management and Analytics Scenario can be considered as coherent platform that spans across multiple subscriptions to allow for scale and overcome platform level limitations. Also, other platform capabilities such as Network Security Group Flow Logs and service specific Diagnostic Settings can be used to capture necessary network and service logs that can be used to inspect traffic. Such logs can be captured at scale through the use of [Azure Policies](/infra/Policies/PolicyDefinitions/DiagnosticSettings/).

In some scenarios, traffic needs to be limited due to regulatory or legal implications. For instance, GDPR requires certain datasets to stay within a European datacentre and therefore would not allowed to be transferred across regions. To comply with such rules and only allow traffic to be sent one direction from East US to West Europe but not vice versa, customers can rely on NSGs. Within the NSGs you can define that traffic originating from East US is denied whereas traffic originating from West Europe would be allowed. This solution approach does not have implications on the bandwidth and latency, but will allow customer to stay compliant while still being able to combine datasets from multiple regions.

This option also has no impact on the DNS architecture and allows using an Azure-native solution based on Azure Private DNS Zones.

Summary: :heavy_plus_sign::heavy_plus_sign::heavy_plus_sign:

#### Cost

---

_When accessing a Private Endpoint across a peered network customers will only ever be charged for the private Endpoint itself and not for the Vnet peering. The official statement can be found [here (FAQ: How will billing work when accessing a Private Endpoint from a peered network?)](https://azure.microsoft.com/en-us/pricing/details/private-link/)._

---

With this network design customers will only pay for the two Private Endpoints (charged per hour) as well as the ingress and egress traffic that is sent through the Private Endpoints. In addition, customers will have to pay [data transfer cost](https://azure.microsoft.com/en-gb/pricing/details/bandwidth/) for traffic between regions. However, due to the statement above, you will NOT be charged for the global Vnet peering ingress and egress cost. In summary, this first option has noteworthy cost benefits compared to the option mentioned below.

Summary: :heavy_plus_sign::heavy_plus_sign::heavy_plus_sign:

#### Bandwidth and Latency

Due to the fact that there are no NVAs limiting throughput and a lower number of hops for cross-region Data Landing Zone data exchange, the bandwidth and latency will be much lower compared to option 2. Physical limits in our datacentres will dictate the bandwidth and latency that can be achieved for cross-region traffic (speed of fibre cables/light, gateways and routers).

Summary: :heavy_plus_sign::heavy_plus_sign::heavy_plus_sign:

#### Summary

Global Vnet peering between Data Landing Zones in different regions can have tremendous benefits especially as the cross-region data traffic increases inside the data platform. Service management will be much simplified, the core Azure platform team will be relieved and use cases that require low latency and high bandwith will benefit from this option. Also, from a cost perspective there are benefits that should be considered when deciding about cross-region Data Landing Zone connectivity.

### 2. Traditional Spoke-Hub-Hub-Spoke Design (NOT Recommended)

The second option proposes to rely on the traditional Spoke-Hub-Hub-Spoke design to transfer data cross-regions. In this scenario, if a virtual machine in a Data Landing Zone A hosted in West Europe loads a dataset that is stored in a storage account hosted in a Data Landing Zone B hosted in East US, data would traverse two local Vnet peerings (connectivity between hub and spokes), one global Vnet peering (connectivity between hubs) and two Gateways or NVAs before it gets loaded by the virtual machine and then stored back into the local storage account.

#### User Access Management

There are no particular pros or cons that are related to any of the proposed options for cross-region Data Landing Zone connectivity.

Summary: :heavy_plus_sign:/:heavy_minus_sign:

#### Service Management

A benefit of this solution approach is that it is well-known and consistent with other cross-region connectivity patterns. Therefore, this option is easy to adopt and implement by customers. This option also has no impact on the DNS architecture and allows using an Azure-native solution based on Azure Private DNS Zones.

This connectivity option works seamless if setup correctly, but also has certain downsides based on our experience. By default, such cross-region traffic is most often denied and needs to be enabled on a case-by-case basis. This means, that for each and every required cross-region data access requirement, a ticket would have to be submitted to the core Azure platform team to allow-list the particular connection between the virtual machine and storage account cross-region. This can create a serious management overhead and can slow-down data project teams, because they are not able to access the data they need to.

Another point that should be considered when choosing this option is that the connectivity hubs act as single point of failures. In case of a downtime of the NVAs or the Gateways, connectivity will fail and corresponding data pipelines will also fail. In addition, there is a high risk of misconfiguration of routes in the connectivity hubs. Such misconfiguration can again cause serious downtime in the data platform and can lead to a series of failures of dependent workflows and data products.

Lastly, customers should monitor the amount of data that needs to be transferred across regions. Over time, this can result in gigabytes or terabytes of data that is sent through the central instances. However, the bandwidth of existing NVAs is often limited to a one- or two-digit gigabyte throughput. Therefore, the appliances can act as a critical bottleneck limiting the traffic flowing between regions and therefore limiting the shareability of data assets. This may require scaling mechanisms for the shared network resources, which can be a time consuming and costly exercise that may even have an impact on other workloads in the tenant.

Summary: :heavy_minus_sign:

#### Cost

---

_When accessing a Private Endpoint across a peered network customers will only ever be charged for the private Endpoint itself and not for the Vnet peering. The official statement can be found [here (FAQ: How will billing work when accessing a Private Endpoint from a peered network?)](https://azure.microsoft.com/en-us/pricing/details/private-link/)._

---

Customers will have to pay for the two Private Endpoints of the Storage Accounts (charged per hour) as well as the ingress and egress traffic that is sent through the Private Endpoints to load the raw and store the processed dataset. In addition, the customer will be charged for the ingress and egress of one local Vnet peering as well as the global Vnet peering between the connectivity hubs. Due to the statement above, the first Vnet peering in the East US region will not be charged. Lastly, customers will end up with very significant cost for the central NVAs when choosing this network design. The high cost will be generated either because additional licenses need to be purchased to scale out based on demand or it will be generated because of the charge per processed gigabyte as it is done with Azure Firewall.

Summary: :heavy_minus_sign::heavy_minus_sign::heavy_minus_sign:

#### Bandwidth & Latency

This network design has serious limitations from a bandwidth perspective. The central NVAs will become critical bottlenecks as the platform grows, which will limit cross-region Data Landing Zone use cases and sharing of datasets and most likely lead to a situation where multiple copies of datasets will be created over time. In addition to bandwidth, latency will be heavily impacted by that network design, which is especially critical for real-time analytics scenarios, as data will have to traverse a large number of hops.

Summary: :heavy_minus_sign::heavy_minus_sign::heavy_minus_sign:

#### Summary

This setup is well-known and established at many customers and therefore is easy to establish in an existing environment. However, customers should consider the downsides that come with the Spoke-Hub-Hub-Spoke connectivity especially from a service management, cost, and bandwidth & latency perspective. Especially as the number of cross-region use cases grows, this setup will show its challenges.

### Conclusion - Cross-region Data Landing Zone Connectivity

After reviewing the two options for cross-region Data Landing Zone connectivity, it becomes clear that [Option 1: Global Vnet peering](#1-global-vnet-peering-recommended) between Data Landing Zone has a number of advantages compared to option 2 and therefore is the recommended approach as the amount of data that needs to be exchanged across regions grows. This option can be easily managed and provides compliant, cost effective and performant connectivity across regions.

Nonetheless, [Option 2: Traditional Spoke-Hub-Hub-Spoke Design](#2-traditional-spoke-hub-hub-spoke-design-not-recommended) can be a viable option while the need for cross-region data exchange and the data volume is low.

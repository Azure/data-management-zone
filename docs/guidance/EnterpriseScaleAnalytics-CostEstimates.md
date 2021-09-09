# Cost Estimates

This document will provide users an overview of what monthly cost can be expected when using Enterprise-Scale Analytics. Links to the official Cost Calculator will be provided where users can make changes depending on the expected amount of data and data throughput. All cost calculations will specify base cost of Enterprise-Scale Analytics. Base cost means the cost that occur, if no data workloads run inside the respective subscriptions.

## Data Management Zone

In a production scenario, it is recommended to rely on the Azure Firewall and Private DNS Zones hosted in the connectivity Hub of [Enterprise-Scale Landing Zones](https://github.com/Azure/Enterprise-Scale). In MVPs, users may rely on the Azure Firewall and Private DNS Zones bundled with Enterprise-Scale Analytics. Hency, two different cost calclations must be made which can be found below:

- [Data Management Zone w/o Azure Firewall and Private DNS Zones](https://azure.com/e/81ea206a75764d6ba390332f04d3fbe1)
- [Data Management Zone w/ Azure Firewall and Private DNS Zones](https://azure.com/e/7461e20e019a4d39aa653e4e516f23af)

Please keep in mind that the following services are not listed here, because they are not available in the official Pricing Calculator or the Pricing Calculator does not allow to set the compute hours to 0:

| Service Name             | Additional Cost |
|:------------------------:|:---------------:|
| Azure Purview            | Yes             |
| Synapse Private Link Hub | Yes             |
| Route Table              | No              |
| Network Security Group   | No              |

## Data Landing Zone

For the Data Landing Zone, please refer to the following cost calculation:

- [Data Landing Zone](https://azure.com/e/55cb6feafcc24cec8cfeb10486d54ab5)

Please keep in mind that when the SQL Pool in the shared product resource group is not stoped, cost will increase by $1,102.30.

Please keep in mind that the following services are not listed here, because they are not available in the official Pricing Calculator or the Pricing Calculator does not allow to set the compute hours to 0:

| Service Name             | Additional Cost |
|:------------------------:|:---------------:|
| Azure Purview            | Yes             |
| Azure Databricks         | No              |
| Route Table              | No              |
| Network Security Group   | No              |

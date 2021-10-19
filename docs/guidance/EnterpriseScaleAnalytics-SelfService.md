# Scalability and Self-Service in Enterprise-Scale Anayltics

Efficient scaling within an Enterprise Data Platform is a much desired goal of many organizations and IT organizations as business units should be enabled to build their own (data) solutions and applications that fulfill their requirements and needs. However. achieving this goal is a serious challenge as many existing data platforms are not built around the core concepts of scalability and decentralized ownership. This is not only true from an architectural standpoint, but also becomes noticable when looking at the team structure within many existing data platform.

## Introduction

Today, many enterprises have built large data platform monoliths around the concept of a single Azure Data Lake Gen2 account and potentially even a single storage container. In addition, a single Azure subscription is most often used for all data platform related tasks and the concept of subscription level scaling is absent in most architectural patterns. This can hinder continued adoption of Azure if users run into any of the [well-know Azure subscription or service-level limitations](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits). Even though some of the constraints are soft-limits, hitting these can still have a significant impact within a data platform that should be avoided at best.

Also, many organizations have organized their data platform architecture and teams around functional responsibilities and pipeline stages that need to be applied to the various data assets of an organization. As a result, specialized teams within a data platform own an orthogonal solution such as ingestion, cleansing, aggregation or serving. This organizational and architectural concept leads to a dramatic loss of velocity, because when data consumers on the serving layer require new data assets to be onboarded or functional changes to be implemented for a specific data asset the following processes will need to be followed o safely roll out these changes:

- The Data Consumer has to submit a ticket to the functional teams being responsible for the respective piepline stages.
- Synchronization is now required between the functional teams as new ingestion services will be required, which will lead to changes required in the data cleansing layer, which will lead to changes on the data aggregation layer, which will again cause changes to be impleented on the serving layer. In summary, all pipelines stages may be impacted by the requested changes and clear impact on the processig staged will not be visible to any of these teams as no onw overviews the end-to-end lifecycle.
- In addition to the synchronization that is required between the various teams, the teams have to design a very well defined release plan in order to not impact existing consumers or pipelines. This dependency management further increases the management overhead.
- All teams included in the requested change are most likely no subject matter experts for the specific data asset. Hence, additional consultation may be required to understand new dataset features or parameter values.
- After applying all changes, the Data Consumer needs to be notified that the data asset is ready to be consumed.

If we now take into consideration that within a large organization there is not a single data consumer but thousands of data consumers, the process described above makes clear why velocity is heavily impacted by such an architectural and organizational pattern. The centralized teams quickly become a bottleneck for the business units, which will ultimately result in slower innovations on the platform, limited effectiveness of data consumers and possibly even to a situation where individual business units decide to build their own data platform.

## Scalability in Enterprise-Scale Analytics

Enterprise-Scale Analytics (ESA) uses two core concepts to overcome the issues mentioned in the [introduction](#introduction) above:

- Scaling through the concept of Data Landing Zones.
- Scaling through the concept of Data Product and Data Integrations to enable distributed and decentralized data ownership.

The following paragraphs will elaborate on these core concepts and will also describe how self-service can be enabled for Data Products.

## Scaling with Data Landing Zones

Enterprise-Scale Analytics is centered around the concepts of Data Management Zone and Data Landing Zone. Each of these artifacts should land in a seperate Azure subscription to allow for clear seperation of duties, to follow the least privilige principle and to partially address the first issue mentioned in the [introduction](#introduction) around subscription scale issues. Hence, the minimal setup of Enterprise-Scale Analytics consists of a single Data Management Zone and a single Data Landing Zone.

For large-scale data platform deployments, a single Data Landing Zone and hence a single subscription will not be sufficient, especially if we take into account that companies build these platforms and make the respective investments to consistently and efficiently scale their data and analytics efforts in the upcoming years. Therefore, to fully overcome the subscription-level limitations and embrace the "subscription as scale unit" concept from [Enterprise-Scale Landing Zones](https://github.com/Azure/Enterprise-Scale), ESA allows an institution to further increase the data platform footprint by adding additional Data Landing Zones to the architecture.

The question of how many Data Landing Zones an organization requires should be discussed and defined upfront before adopting the ESA prescripte architectural pattern. This is considered to be one of the most important design decisions, because it lays the foundation for an effective and efficient data platform. When done right, it will prevent enterprises from ending up in a migration project of data products from one Data Landing Zone to another and will allow an effective and consistent scaling of any big data and analytics efforts for the upcoming years.

The following factors should be considered when deciding about how many Data Landing Zones should be deployed:

- *Data Domains*: What data domains does the organization encompass and which data domains will land on the data platform?
- *Business units and cost allocation*: Are shared services like storage accounts paid centrally or do these need to be split by business unit or domain? 
- *Location*: In which Azure Regions will the organization deploy their data platform? Will the platform be hosted in a single region or will it span across multiple regions? Are there data residency requirements that need to be taken into account?
- *Data classifications and highly-confidential data*: What data classifications exist within the organization? Does the organization have datasets that are classified as highly-confidential and do these datasets require special treatment in form of just in time access, customer managed keys (CMK) or additional encryption being enforced? May these additional security mechanisms even impact usability of the data platform and data product development?

If an enterprise decides to move forward with 
This scaling mechanism allows organizations to naturally increase the size of their data platform over time. Additional Data Landing Zones can be added in a phased approach and customers are not forced to start with a multi-Data Ladning Zone setup right from the start.


- link to networking doc
- driving factors on why to add additional landing zones
- how to organize landing zones
- how to start
- multiple storage accounts within a landing zone and due to multiple landing zones

allow for scalability without running into the 




- a distributed decentralized data ownership model to overcome the challenges mentioned above. Instead of a functional split, a domain-driven and cross-functional ownership model is used to 
- In order to scale within an Enterprise Data Platform a more distributed approach needs to be followed
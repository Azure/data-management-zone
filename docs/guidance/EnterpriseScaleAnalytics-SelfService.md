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

## Methods of scaling in Enterprise-Scale Analytics

Enterprise-Scale Analytics (ESA) uses two core concepts to overcome the issues mentioned in the [introduction](#introduction) above:

- Scaling through the concept of Data Landing Zones.
- Scaling through the concept of Data Product or Data Integrations to enable distributed and decentralized data ownership.

The following paragraphs will elaborate on these core concepts and will also describe how self-service can be enabled for Data Products.

### Scaling with Data Landing Zones

Enterprise-Scale Analytics is centered around the concepts of Data Management Zone and Data Landing Zone. Each of these artifacts should land in a seperate Azure subscription to allow for clear seperation of duties, to follow the least privilige principle and to partially address the first issue mentioned in the [introduction](#introduction) around subscription scale issues. Hence, the minimal setup of Enterprise-Scale Analytics consists of a single Data Management Zone and a single Data Landing Zone.

For large-scale data platform deployments, a single Data Landing Zone and hence a single subscription will not be sufficient, especially if we take into account that companies build these platforms and make the respective investments to consistently and efficiently scale their data and analytics efforts in the upcoming years. Therefore, to fully overcome the subscription-level limitations and embrace the "subscription as scale unit" concept from [Enterprise-Scale Landing Zones](https://github.com/Azure/Enterprise-Scale), ESA allows an institution to further increase the data platform footprint by adding additional Data Landing Zones to the architecture. Furthermore, this also addresses the concern of a single Azure Data Lake Gen2 being used for a whole company as each Data Landing Zone comes with a set of three Data Lakes.

The question of how many Data Landing Zones an organization requires should be discussed and defined upfront before adopting the ESA prescripte architectural pattern. This is considered to be one of the most important design decisions, because it lays the foundation for an effective and efficient data platform. When done right, it will prevent enterprises from ending up in a migration project of data products and data assets from one Data Landing Zone to another and will allow an effective and consistent scaling of any big data and analytics efforts for the upcoming years.

The following factors should be considered when deciding about how many Data Landing Zones should be deployed:

- *Data Domains*: What data domains does the organization encompass and which data domains will land on the data platform?
- *Cost allocation*: Are shared services like storage accounts paid centrally or do these need to be split by business unit or domain? 
- *Location*: In which Azure Regions will the organization deploy their data platform? Will the platform be hosted in a single region or will it span across multiple regions? Are there data residency requirements that need to be taken into account?
- *Data classifications and highly-confidential data*: What data classifications exist within the organization? Does the organization have datasets that are classified as highly-confidential and do these datasets require special treatment in form of just in time access, customer managed keys (CMK), fine grained network controls or additional encryption being enforced? May these additional security mechanisms even impact usability of the data platform and data product development?

Considering all these factors, an enterprise should target no more than 15 Data Landing Zones as there is also some management overhead attached to each Data Landing Zone. 

It is important to emphasize that Data Landing Zones are not creating Data Silos within an organization, as the recommended network setup in ESA enables secure and in-place data sharing across Landing Zones and therefore enables innovation across data domains and business units. Please read the [network design guidance](/docs/guidance/EnterpriseScaleAnalytics-NetworkArchitecture.md) to find out more about how this is achieved.

Lastly, it needs to be highlighted that the prescriptive ESA architecture and the concept of Data Landing Zones allows corporations to naturally increase the size of their data platform over time. Additional Data Landing Zones can be added in a phased approach and customers are not forced to start with a multi-Data Landing Zone setup right from the start. When adoptig the pattern, companies should start prioritinzing few Dat aLanding Zones as well as Data Products that should land inside them respectively, to make sure that the adoption of ESA is successful.

### Scaling with Data Products

Within a Data Landing Zone, Enterprise-Scale Analytics allows organizations scale through the concept of Data Integrations and Data Products. A Data Integration or Data Product is an environment in form of resource group that allows cross-functional teams to implement data solutions and workloads on the platform. These teams then take care of the ingest (only for Data Integration), cleansing, aggregation and serving tasks for a particular data-domain, sub-domain, dataset or project.

A Data Integration pattern is a special kind of Data Product that is mainly concerned with the integration of data assets from source systems outside of the data platform onto a Data Landing Zone. These consistent data integration implementations reduce the impact on the transactional systems and allow multiple Data Product teams to consume the same dataset version without being concerned about the integration and without having to repeat the integration task.
Data Products on the other hand are consuming one or multiple data assets within the same Data Landing Zone or across multiple Data Landing Zones to generate new data assets, insights or business value. The resulting data assets may again be shared with other Data Product teams to enhance the value being created within the business even further.

With the Data Integration concept, Enterprise-Scale Analytics addresses the data integration and responsibility issue mentioned in the [introduction](#introduction). Instead of having an architectural design build around monolithic functional responsibilities for the ingestion of tables and integration of source systems, the referenece design is pivoting the design towards a distributed, data domains driven architecture, where cross functional teams take over the end-to-end functional responsibility and ownership for the respective data scope. In summary, this means that instead of having a centralized technical stack and team being responsible for each and every orthogonal solution of the data processing workflow, we are distributing the end-to-end responsibility from ingestion to the serving layer for data domains or sub-domains across multiple autonomously working cross-functional Data Integration teams. The Data Integration teams own a domain or sub-domain capability and also must be encouraged to serve datasets for access by any team for any purpose or project they may be working on.

This architectural paradigm shift ultimately leads to an increased velocity within the data platform as data consumers do no longer have to rely on a set of centralized teams or have to fight for prioritization of the requested changes. As smaller teams take ownership of the end-to-end integration workflow, the feedback loop between data provider and data consumer is much shorter and therefore allows for much quicker prioritization, development cycles and a more agile development process. Additionaly, complex synchronization processes and release plans between teams are no longer required as the cross-functional Data Integration team has full visibility of the end-to-end technical stack as well as any implications that may arise due to the implemented changes. The team can apply software engineering practices to run unit and integration tests to minimize overall impact on consumers. 

In an ideal world, the data integration would be owned by the same team that owns the source systems. But the team should in general not ony consist of data engineers that work on the source systems, but also of subject matter experts (SMEs) for these datasets, cloud engineers and data product owners. Such a cross-functional team setup reduces the communication requird to teams outside and will be essential when developing the complete stack from infrastructure to actual data pipelines.

Integrated datasets from source systems become the foundation of the data platform and will enable Data Product teams to further innovate on top of the business fact tables to eventually improve decision making and optimize business processes. Both Data Integration and Data Product teams should offer SLAs to consumers and ensure hat agreements are met. These SLAs can be related to data quality, timeliness, error rates, uptime and other tasks.

### Summary

The sections above are summarizing the scaling machanisms within Enterprise-Scale Analytics that organizations can use to grow their data estate within Azure over time without running into well-known technical limitations. Both scaling mechanisms are helping to overcome different technical complexities and can be used in an effecient and simple way.

The previous section promises agility and quick development cycles within the Data Integration and Data Product environments. However, this will only be possible if teams get the required access rights to develop independently and roll out new dataset versions and features over time in a self-service manner. How this can be achieved will be covered as part of the next section.

## Enabling Self-service for Data Products in Enterprise-Scale Analytics 




- Data Catalog access, rg access, shared services access

- policies to keep management plane secure

- data product templates as blueprint that is handed over to domain and product teams so that they take over ownership of the e2e solution
- blueprints are lowering the 'lead time to create a new data product' on the infrastructure
- can also start from scratch
- self-service wrt data services or any services
- decentralized cost ownership also means that the team is paying
- access to repo and board
# Scalability and Self-Service in Enterprise-Scale Anayltics

Efficient scaling within an Enterprise Data Platform is a much desired goal of many customers and IT organizations as business units should be enabled to build their own (data) solutions and applications that fulfill their requirements and needs. However. achieving this goal is a serious challenge as many existing data platforms are not built around the core concepts of scalability and decentralized ownership. This is not only true from an architectural standpoint, but also becomes noticable when looking at the team structure within many existing data platform.

## Introduction

Today, many customers have built large data platform monoliths around the concept of a single Azure Data Lake Gen2 account and potentially even a single storage container. In addition, a single Azure subscription is most often used for all data platform related tasks and the concept of subscription level scaling is absent in most architectural patterns. This can hinder continued adoption of Azure if customers run into any of the [well-know Azure subscription or service-level limitations](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits). Even though some of the constraints are soft-limits, hitting these can still have a significant impact within a data platform that should be avoided at best.

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

Enterprise-Scale Analytics is centered around the concepts of Data Management Zone and Data Landing Zone. Each of these artifacts should land into a seperate Azure subscription to allow for clear seperation of duties, to follow the least privilige principle and to partially address the first issue around subscription scale issues. Hence, the minimal setup of Enterprise-Scale Analytics consists of a single Data Management Zone and a single Data Landing Zone.

To fully overcome the subscription-level allow for scalability without running into the 




- a distributed decentralized data ownership model to overcome the challenges mentioned above. Instead of a functional split, a domain-driven and cross-functional ownership model is used to 
- In order to scale within an Enterprise Data Platform a more distributed approach needs to be followed
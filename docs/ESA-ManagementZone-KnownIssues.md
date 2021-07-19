# Known issues

## Error: MissingSubscriptionRegistration

**Error Message:**

```sh
ERROR: Deployment failed. Correlation ID: ***
  "error": ***
    "code": "MissingSubscriptionRegistration",
    "message": "The subscription is not registered to use namespace 'Microsoft.DocumentDB'. See https://aka.ms/rps-not-found for how to register subscriptions.",
    "details": [
      ***
        "code": "MissingSubscriptionRegistration",
        "target": "Microsoft.DocumentDB",
        "message": "The subscription is not registered to use namespace 'Microsoft.DocumentDB'. See https://aka.ms/rps-not-found for how to register subscriptions."

```

**Solution:**

This error message appears, in case during the deployment it tries to create a type of resource which has never been deployed before inside the subscription. We recommend to check prior the deployment whether the required resource providers are registered for your subscription and if needed, register them through the `Azure Portal`, `Azure Powershell` or `Azure CLI` as mentioned [here](https://docs.microsoft.com/azure/azure-resource-manager/management/resource-providers-and-types).

**Error Message:**

```sh
"statusMessage": "{\"error\":{\"code\":\"InvalidTemplateDeployment\",\"message\":\"The template deployment 'deploy.purview' is not valid according to the validation procedure. The tracking id is '9e22893b-1e0a-48ba-800c-77a27a86cade'. See inner errors for details.\",\"details\":[{\"code\":\"1000\",\"message\":\"Failed to list providers from ARM. Exception: The client '38a6ed90-8590-42fb-b09f-fbcf6f6849c3' with object id '38a6ed90-8590-42fb-b09f-fbcf6f6849c3' does not have authorization to perform action 'Microsoft.Resources/subscriptions/providers/read' over scope '/subscriptions/9ae0dd4c-d127-4901-bb76-46d39676a2cc' or the scope is invalid. If access was recently granted, please refresh your credentials.\"}]}}"
"eventCategory": "Administrative",

```

**Solution:**

**Error Purview Specific** This error message appears during the deployment of Purview in case it was not registered inside the subscription. We recommend to check prior the deployment whether the 'purview' resource providers is registered for your subscription and if needed, register it through the `Azure Portal`, `Azure Powershell` or `Azure CLI` as mentioned [here](https://docs.microsoft.com/azure/azure-resource-manager/management/resource-providers-and-types).

< Previous: [Code structure](./ESA-ManagementZone-CodeStructure.md)

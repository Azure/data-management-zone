# Data Management Zone - Known Issues

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

OR

```sh
"statusMessage": "{\"error\":{\"code\":\"InvalidTemplateDeployment\",\"message\":\"The template deployment 'deploy.purview' is not valid according to the validation procedure. The tracking id is '9e22893b-1e0a-48ba-800c-77a27a86cade'. See inner errors for details.\",\"details\":[{\"code\":\"1000\",\"message\":\"Failed to list providers from ARM. Exception: The client '38a6ed90-8590-42fb-b09f-fbcf6f6849c3' with object id '38a6ed90-8590-42fb-b09f-fbcf6f6849c3' does not have authorization to perform action 'Microsoft.Resources/subscriptions/providers/read' over scope '/subscriptions/9ae0dd4c-d127-4901-bb76-46d39676a2cc' or the scope is invalid. If access was recently granted, please refresh your credentials.\"}]}}"
"eventCategory": "Administrative",
```

**Solution:**

This error message appears, in case during the deployment it tries to create a type of resource which has never been deployed before inside the subscription. We recommend to check prior the deployment whether the required resource providers are registered for your subscription and if needed, register them through the `Azure Portal`, `Azure Powershell` or `Azure CLI` as mentioned [here](https://docs.microsoft.com/azure/azure-resource-manager/management/resource-providers-and-types).

## Error: Purview soft-limit reached in Tenant and Region

**Error Message:**

```sh
ERROR: Deployment failed. Correlation ID: ***
{
    "status": "Failed",
    "error": {
        "code": "DeploymentFailed",
        "message": "At least one resource deployment operation failed. Please list deployment operations for details. Please see https://aka.ms/DeployOperations for usage details.",
        "details": [
            {
                "code": "BadRequest",
                "message": "{\r\n \"error\": {\r\n \"code\": \"InvalidTemplateDeployment\",\r\n \"message\": \"The template deployment 'purview001' is not valid according to the validation procedure. The tracking id is '<tracking_id>'. See inner errors for details.\",\r\n \"details\": [\r\n {\r\n \"code\": \"2005\",\r\n \"message\": \"Tenant <tenant-id> with 100 accounts has surpassed its resource quota for southeastasia location. Please try creating in other available locations or contact support.\"\r\n }\r\n ]\r\n }\r\n}"
            }
        ]
    }
}
```

**Solution:**

This error message appears, if the Purview soft-limit has been reached inside your tenant. Please open a support ticket and ask for a quote increase in the selected region.

## Error: Failed to get resource provider Microsoft.EventHub

**Error Message**

```sh
{
  "error": {
    "code": "InvalidTemplateDeployment",
    "message": "The template deployment 'purview001' is not valid according to the validation procedure. The tracking id is '<tracking_id>'. See inner errors for details.",
    "details": [
      {
        "code": "23001",
        "message": "Failed to get resource provider Microsoft.EventHub, requestId: <request_id>. Exception: (Exception) ErrorCode:AuthorizationFailed. Message:The client '<client_id>' with object id '<object_id>' does not have authorization to perform action 'Microsoft.Resources/subscriptions/providers/read' over scope '/subscriptions/subscription_id' or the scope is invalid. If access was recently granted, please refresh your credentials.. Target:.."
      }
    ]
  }
}
```

**Solution:**

This error message appears, when deploying Purview and the `Microsoft.EventHub`, `Microsoft.Storage` and/or `Microsoft.Purview` Resource Provider (RP) is not registered for the subscription or it was registered during early preview phase. If the `Microsoft.Purview` RP is already registered, please un-register and re-register it. We have released a fix to our Deploy To Azure Buttons to overcome this issue until it gets fixed on the Purview side. If you still run into this problem, please open an Issue in this repo and start (re-)registering the three Resource Providers manually through the `Azure Portal`, `Azure Powershell` or `Azure CLI` as mentioned [here](https://docs.microsoft.com/azure/azure-resource-manager/management/resource-providers-and-types). Once that is done, use the "Redeploy" button on the failed deployment to restart the deployment and successfully deploy the components.

>[Previous (Option (a) GitHub Actions)](/docs/EnterpriseScaleAnalytics-GitHubActionsDeployment.md)
>[Previous (Option (b) Azure DevOps)](/docs/EnterpriseScaleAnalytics-AzureDevOpsDeployment.md)

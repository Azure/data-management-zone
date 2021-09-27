# Documentation:
#  - Test Parameters: https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/test-toolkit#test-parameters
#  - Test Cases: https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/test-cases
@{
    # Test = @( )
    Skip = @(
        'Template Should Not Contain Blanks',
        'DeploymentTemplate Must Not Contain Hardcoded Uri'
        'DependsOn Best Practices'
        'IDs Should Be Derived From ResourceIDs'
        'Parameters Must Be Referenced'
        'Variables Must Be Referenced'
    )
}

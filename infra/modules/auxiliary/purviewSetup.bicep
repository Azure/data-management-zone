// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a Purview account.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param userAssignedIdentityId string
param purviewId string
param purviewRootCollectionAdminObjectIds array

// Variables
var purviewName = length(split(purviewId, '/')) >= 9 ? last(split(purviewId, '/')) : 'incorrectSegmentLength'
var purviewSetupName = '${purviewName}-setup'

// Resources
resource purviewSetup 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: purviewSetupName
  location: location
  tags: tags
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    azPowerShellVersion: 'az6.4'
    arguments: '-PurviewId \\"${purviewId}\\" -PurviewRootCollectionAdmins \\"${purviewRootCollectionAdminObjectIds}\\"'
    cleanupPreference: 'OnSuccess'
    containerSettings: {
      containerGroupName: purviewSetupName
    }
    environmentVariables: []
    forceUpdateTag: '1'
    scriptContent: loadTextContent('../../../code/SetupPurview.ps1')
    retentionInterval: 'P1D'
    supportingScriptUris: []
    timeout: 'PT30M'
  }
}

// Outputs

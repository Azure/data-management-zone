// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to setup a Purview account.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param userAssignedIdentityId string
param purviewId string
param purviewRootCollectionAdminObjectIds array
param forceUpdateTag string = utcNow()

// Variables
var purviewName = length(split(purviewId, '/')) >= 9 ? last(split(purviewId, '/')) : 'incorrectSegmentLength'
var purviewSetupName = '${purviewName}-setup'
var purviewRootCollectionAdminsInput = replace(replace(string(purviewRootCollectionAdminObjectIds), '[', ''), ']', '')

// Resources
resource purviewSetup 'Microsoft.Resources/deploymentScripts@2020-10-01' = if(length(purviewRootCollectionAdminObjectIds) > 0) {
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
    azPowerShellVersion: '6.3'
    arguments: '-PurviewId \\"${purviewId}\\" -PurviewRootCollectionAdmins ${purviewRootCollectionAdminsInput}'
    cleanupPreference: 'OnSuccess'
    containerSettings: {
      containerGroupName: purviewSetupName
    }
    environmentVariables: []
    forceUpdateTag: forceUpdateTag
    scriptContent: loadTextContent('../../../code/SetupPurview.ps1')
    retentionInterval: 'P1D'
    supportingScriptUris: []
    timeout: 'PT30M'
  }
}

// Outputs

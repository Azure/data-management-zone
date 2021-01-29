<#
Copyright (c) Microsoft Corporation. All rights reserved.
Licensed under the MIT License.
Source: https://github.com/Microsoft/AzureAutomation-Account-Modules-Update
#>

<#
.SYNOPSIS
Update Azure PowerShell modules in an Azure Automation account.
.DESCRIPTION
This Azure Automation runbook updates Azure PowerShell modules imported into an
Azure Automation account with the module versions published to the PowerShell Gallery.
Prerequisite: an Azure Automation account with an Azure Run As account credential.
.PARAMETER ResourceGroupName
The Azure resource group name.
.PARAMETER AutomationAccountName
The Azure Automation account name.
.PARAMETER SimultaneousModuleImportJobCount
(Optional) The maximum number of module import jobs allowed to run concurrently.
.PARAMETER AzureModuleClass
(Optional) The class of module that will be updated (AzureRM or Az)
If set to Az, this script will rely on only Az modules to update other modules.
Set this to Az if your runbooks use only Az modules to avoid conflicts.
.PARAMETER AzureEnvironment
(Optional) Azure environment name.
.PARAMETER Login
(Optional) If $false, do not login to Azure.
.PARAMETER ModuleVersionOverrides
(Optional) Module versions to use instead of the latest on the PowerShell Gallery.
If $null, the currently published latest versions will be used.
If not $null, must contain a JSON-serialized dictionary, for example:
    '{ "AzureRM.Compute": "5.8.0", "AzureRM.Network": "6.10.0" }'
or
    @{ 'AzureRM.Compute'='5.8.0'; 'AzureRM.Network'='6.10.0' } | ConvertTo-Json
.PARAMETER PsGalleryApiUrl
(Optional) PowerShell Gallery API URL.
.LINK
https://docs.microsoft.com/en-us/azure/automation/automation-update-azure-modules
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
param(
    [Parameter(Mandatory = $true)]
    [string] $ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $AutomationAccountName,

    [int] $SimultaneousModuleImportJobCount = 10,

    [string] $AzureModuleClass = 'AzureRM',

    [string] $AzureEnvironment = 'AzureCloud',

    [bool] $Login = $true,
    
    [string] $ModuleVersionOverrides = $null,
    
    [string] $PsGalleryApiUrl = 'https://www.powershellgallery.com/api/v2'
)

$ErrorActionPreference = "Continue"

#region Constants

$script:AzureRMProfileModuleName = "AzureRM.Profile"
$script:AzureRMAutomationModuleName = "AzureRM.Automation"
$script:GetAzureRmAutomationModule = "Get-AzureRmAutomationModule"
$script:NewAzureRmAutomationModule = "New-AzureRmAutomationModule"

$script:AzAccountsModuleName = "Az.Accounts"
$script:AzAutomationModuleName = "Az.Automation"
$script:GetAzAutomationModule = "Get-AzAutomationModule"
$script:NewAzAutomationModule = "New-AzAutomationModule"

$script:AzureSdkOwnerName = "azure-sdk"

#endregion

#region Functions

function ConvertJsonDictTo-HashTable($JsonString) {
    try{
        $JsonObj = ConvertFrom-Json $JsonString -ErrorAction Stop
    } catch [System.ArgumentException] {
        throw "Unable to deserialize the JSON string for parameter ModuleVersionOverrides: ", $_
    }

    $Result = @{}
    foreach ($Property in $JsonObj.PSObject.Properties) {
        $Result[$Property.Name] = $Property.Value
    }

    $Result
}

# Use the Run As connection to login to Azure
function Login-AzureAutomation([bool] $AzModuleOnly) {
    try {
        $RunAsConnection = Get-AutomationConnection -Name "AzureRunAsConnection"
        Write-Output "Logging in to Azure ($AzureEnvironment)..."
        
        if (!$RunAsConnection.ApplicationId) {
            $ErrorMessage = "Connection 'AzureRunAsConnection' is incompatible type."
            throw $ErrorMessage            
        }
        
        if ($AzModuleOnly) {
            Connect-AzAccount `
                -ServicePrincipal `
                -TenantId $RunAsConnection.TenantId `
                -ApplicationId $RunAsConnection.ApplicationId `
                -CertificateThumbprint $RunAsConnection.CertificateThumbprint `
                -Environment $AzureEnvironment

            Select-AzSubscription -SubscriptionId $RunAsConnection.SubscriptionID  | Write-Verbose
        } else {
            Add-AzureRmAccount `
                -ServicePrincipal `
                -TenantId $RunAsConnection.TenantId `
                -ApplicationId $RunAsConnection.ApplicationId `
                -CertificateThumbprint $RunAsConnection.CertificateThumbprint `
                -Environment $AzureEnvironment

            Select-AzureRmSubscription -SubscriptionId $RunAsConnection.SubscriptionID  | Write-Verbose
        }
    } catch {
        if (!$RunAsConnection) {
            $RunAsConnection | fl | Write-Output
            Write-Output $_.Exception
            $ErrorMessage = "Connection 'AzureRunAsConnection' not found."
            throw $ErrorMessage
        }

        throw $_.Exception
    }
}

# Checks the PowerShell Gallery for the latest available version for the module
function Get-ModuleDependencyAndLatestVersion([string] $ModuleName) {

    $ModuleUrlFormat = "$PsGalleryApiUrl/Search()?`$filter={1}&searchTerm=%27{0}%27&targetFramework=%27%27&includePrerelease=false&`$skip=0&`$top=40"
        
    $ForcedModuleVersion = $ModuleVersionOverridesHashTable[$ModuleName]

    $CurrentModuleUrl =
        if ($ForcedModuleVersion) {
            $ModuleUrlFormat -f $ModuleName, "Version%20eq%20'$ForcedModuleVersion'"
        } else {
            $ModuleUrlFormat -f $ModuleName, 'IsLatestVersion'
        }

    $SearchResult = Invoke-RestMethod -Method Get -Uri $CurrentModuleUrl -UseBasicParsing

    if (!$SearchResult) {
        Write-Verbose "Could not find module $ModuleName on PowerShell Gallery. This may be a module you imported from a different location. Ignoring this module"
    } else {
        if ($SearchResult.Length -and $SearchResult.Length -gt 1) {
            $SearchResult = $SearchResult | Where-Object { $_.title.InnerText -eq $ModuleName }
        }

        if (!$SearchResult) {
            Write-Verbose "Could not find module $ModuleName on PowerShell Gallery. This may be a module you imported from a different location. Ignoring this module"
        } else {
            $PackageDetails = Invoke-RestMethod -Method Get -UseBasicParsing -Uri $SearchResult.id

            # Ignore the modules that are not published as part of the Azure SDK
            if ($PackageDetails.entry.properties.Owners -ne $script:AzureSdkOwnerName) {
                Write-Warning "Module : $ModuleName is not part of azure sdk. Ignoring this."
            } else {
                $ModuleVersion = $PackageDetails.entry.properties.version
                $Dependencies = $PackageDetails.entry.properties.dependencies

                @($ModuleVersion, $Dependencies)
            }
        }
    }
}

function Get-ModuleContentUrl($ModuleName) {
    $ModuleContentUrlFormat = "$PsGalleryApiUrl/package/{0}"
    $VersionedModuleContentUrlFormat = "$ModuleContentUrlFormat/{1}"

    $ForcedModuleVersion = $ModuleVersionOverridesHashTable[$ModuleName]
    if ($ForcedModuleVersion) {
        $VersionedModuleContentUrlFormat -f $ModuleName, $ForcedModuleVersion
    } else {
        $ModuleContentUrlFormat -f $ModuleName
    }
}

# Imports the module with given version into Azure Automation
function Import-AutomationModule([string] $ModuleName, [bool] $UseAzModule = $false) {

    $NewAutomationModule = $null
    $GetAutomationModule = $null
    if ($UseAzModule) {
        $GetAutomationModule = $script:GetAzAutomationModule
        $NewAutomationModule = $script:NewAzAutomationModule
    } else {
        $GetAutomationModule = $script:GetAzureRmAutomationModule
        $NewAutomationModule = $script:NewAzureRmAutomationModule
    }


    $LatestModuleVersionOnGallery = (Get-ModuleDependencyAndLatestVersion $ModuleName)[0]

    $ModuleContentUrl = Get-ModuleContentUrl $ModuleName
    # Find the actual blob storage location of the module
    do {
        $ModuleContentUrl = (Invoke-WebRequest -Uri $ModuleContentUrl -MaximumRedirection 0 -UseBasicParsing -ErrorAction Ignore).Headers.Location 
    } while (!$ModuleContentUrl.Contains(".nupkg"))

    $CurrentModule = & $GetAutomationModule `
                        -Name $ModuleName `
                        -ResourceGroupName $ResourceGroupName `
                        -AutomationAccountName $AutomationAccountName

    if ($CurrentModule.Version -eq $LatestModuleVersionOnGallery) {
        Write-Output "Module : $ModuleName is already present with version $LatestModuleVersionOnGallery. Skipping Import"
    } else {
        Write-Output "Importing $ModuleName module of version $LatestModuleVersionOnGallery to Automation"

        & $NewAutomationModule `
            -ResourceGroupName $ResourceGroupName `
            -AutomationAccountName $AutomationAccountName `
            -Name $ModuleName `
            -ContentLink $ModuleContentUrl > $null
    }
}

# Parses the dependency got from PowerShell Gallery and returns name and version
function GetModuleNameAndVersionFromPowershellGalleryDependencyFormat([string] $Dependency) {
    if ($null -eq $Dependency) {
        throw "Improper dependency format"
    }

    $Tokens = $Dependency -split":"
    if ($Tokens.Count -ne 3) {
        throw "Improper dependency format"
    }

    $ModuleName = $Tokens[0]
    $ModuleVersion = $Tokens[1].Trim("[","]")

    @($ModuleName, $ModuleVersion)
}

# Validates if the given list of modules has already been added to the module import map
function AreAllModulesAdded([string[]] $ModuleListToAdd) {
    $Result = $true

    foreach ($ModuleToAdd in $ModuleListToAdd) {
        $ModuleAccounted = $false

        # $ModuleToAdd is specified in the following format:
        #       ModuleName:ModuleVersionSpecification:
        # where ModuleVersionSpecification follows the specifiation
        # at https://docs.microsoft.com/en-us/nuget/reference/package-versioning#version-ranges-and-wildcards
        # For example:
        #       AzureRm.profile:[4.0.0]:
        # or
        #       AzureRm.profile:3.0.0:
        # In any case, the dependency version specification is always separated from the module name with
        # the ':' character. The explicit intent of this runbook is to always install the latest module versions,
        # so we want to completely ignore version specifications here.
        $ModuleNameToAdd = $ModuleToAdd -replace '\:.*', ''
            
        foreach($AlreadyIncludedModules in $ModuleImportMapOrder) {
            if ($AlreadyIncludedModules -contains $ModuleNameToAdd) {
                $ModuleAccounted = $true
                break
            }
        }
        
        if (!$ModuleAccounted) {
            $Result = $false
            break
        }
    }

    $Result
}

# Creates a module import map. This is a 2D array of strings so that the first
# element in the array consist of modules with no dependencies.
# The second element only depends on the modules in the first element, the
# third element only dependes on modules in the first and second and so on. 
function Create-ModuleImportMapOrder([bool] $AzModuleOnly) {
    $ModuleImportMapOrder = $null
    $ProfileOrAccountsModuleName = $null
    $GetAutomationModule = $null

    # Use the relevant module class to avoid conflicts
    if ($AzModuleOnly) {
        $ProfileOrAccountsModuleName = $script:AzAccountsModuleName
        $GetAutomationModule = $script:GetAzAutomationModule
    } else {
        $ProfileOrAccountsModuleName = $script:AzureRmProfileModuleName
        $GetAutomationModule = $script:GetAzureRmAutomationModule
    }

    # Get all the non-conflicting modules in the current automation account
    $CurrentAutomationModuleList = & $GetAutomationModule `
                                        -ResourceGroupName $ResourceGroupName `
                                        -AutomationAccountName $AutomationAccountName |
        ?{
            ($AzModuleOnly -and ($_.Name -eq 'Az' -or $_.Name -like 'Az.*')) -or
            (!$AzModuleOnly -and ($_.Name -eq 'AzureRM' -or $_.Name -like 'AzureRM.*' -or
            $_.Name -eq 'Azure' -or $_.Name -like 'Azure.*'))
        }

    # Get the latest version of the AzureRM.Profile OR Az.Accounts module
    $VersionAndDependencies = Get-ModuleDependencyAndLatestVersion $ProfileOrAccountsModuleName

    $ModuleEntry = $ProfileOrAccountsModuleName
    $ModuleEntryArray = ,$ModuleEntry
    $ModuleImportMapOrder += ,$ModuleEntryArray

    do {
        $NextAutomationModuleList = $null
        $CurrentChainVersion = $null
        # Add it to the list if the modules are not available in the same list 
        foreach ($Module in $CurrentAutomationModuleList) {
            $Name = $Module.Name

            Write-Verbose "Checking dependencies for $Name"
            $VersionAndDependencies = Get-ModuleDependencyAndLatestVersion $Module.Name
            if ($null -eq $VersionAndDependencies) {
                continue
            }

            $Dependencies = $VersionAndDependencies[1].Split("|")

            $AzureModuleEntry = $Module.Name

            # If the previous list contains all the dependencies then add it to current list
            if ((-not $Dependencies) -or (AreAllModulesAdded $Dependencies)) {
                Write-Verbose "Adding module $Name to dependency chain"
                $CurrentChainVersion += ,$AzureModuleEntry
            } else {
                # else add it back to the main loop variable list if not already added
                if (!(AreAllModulesAdded $AzureModuleEntry)) {
                    Write-Verbose "Module $Name does not have all dependencies added as yet. Moving module for later import"
                    $NextAutomationModuleList += ,$Module
                }
            }
        }

        $ModuleImportMapOrder += ,$CurrentChainVersion
        $CurrentAutomationModuleList = $NextAutomationModuleList

    } while ($null -ne $CurrentAutomationModuleList)

    $ModuleImportMapOrder
}

# Wait and confirm that all the modules in the list have been imported successfully in Azure Automation
function Wait-AllModulesImported(
            [Collections.Generic.List[string]] $ModuleList,
            [int] $Count,
            [bool] $UseAzModule = $false) {

    $GetAutomationModule = if ($UseAzModule) {
        $script:GetAzAutomationModule
    } else {
        $script:GetAzureRmAutomationModule
    }

    $i = $Count - $SimultaneousModuleImportJobCount
    if ($i -lt 0) { $i = 0 }

    for ( ; $i -lt $Count; $i++) {
        $Module = $ModuleList[$i]

        Write-Output ("Checking import Status for module : {0}" -f $Module)
        while ($true) {
            $AutomationModule = & $GetAutomationModule `
                                    -Name $Module `
                                    -ResourceGroupName $ResourceGroupName `
                                    -AutomationAccountName $AutomationAccountName

            $IsTerminalProvisioningState = ($AutomationModule.ProvisioningState -eq "Succeeded") -or
                                           ($AutomationModule.ProvisioningState -eq "Failed")

            if ($IsTerminalProvisioningState) {
                break
            }

            Write-Verbose ("Module {0} is getting imported" -f $Module)
            Start-Sleep -Seconds 30
        }

        if ($AutomationModule.ProvisioningState -ne "Succeeded") {
            Write-Error ("Failed to import module : {0}. Status : {1}" -f $Module, $AutomationModule.ProvisioningState)                
        } else {
            Write-Output ("Successfully imported module : {0}" -f $Module)
        }
    }               
}

# Uses the module import map created to import modules. 
# It will only import modules from an element in the array if all the modules
# from the previous element have been added.
function Import-ModulesInAutomationAccordingToDependency([string[][]] $ModuleImportMapOrder, [bool] $UseAzModule) {

    foreach($ModuleList in $ModuleImportMapOrder) {
        $i = 0
        Write-Output "Importing Array of modules : $ModuleList"
        foreach ($Module in $ModuleList) {
            Write-Verbose ("Importing module : {0}" -f $Module)
            Import-AutomationModule -ModuleName $Module -UseAzModule $UseAzModule
            $i++
            if ($i % $SimultaneousModuleImportJobCount -eq 0) {
                # It takes some time for the modules to start getting imported.
                # Sleep for sometime before making a query to see the status
                Start-Sleep -Seconds 20
                Wait-AllModulesImported -ModuleList $ModuleList -Count $i -UseAzModule $UseAzModule
            }
        }

        if ($i -lt $SimultaneousModuleImportJobCount) {
            Start-Sleep -Seconds 20
            Wait-AllModulesImported -ModuleList $ModuleList -Count $i -UseAzModule $UseAzModule
        }
    }
}

function Update-ProfileAndAutomationVersionToLatest([string] $AutomationModuleName) {
    # Get the latest azure automation module version 
    $VersionAndDependencies = Get-ModuleDependencyAndLatestVersion $AutomationModuleName

    # Automation only has dependency on profile
    $ModuleDependencies = GetModuleNameAndVersionFromPowershellGalleryDependencyFormat $VersionAndDependencies[1]
    $ProfileModuleName = $ModuleDependencies[0]

    # Create web client object for downloading data
    $WebClient = New-Object System.Net.WebClient

    # Download AzureRM.Profile to temp location
    $ModuleContentUrl = Get-ModuleContentUrl $ProfileModuleName
    $ProfileURL = (Invoke-WebRequest -Uri $ModuleContentUrl -MaximumRedirection 0 -UseBasicParsing -ErrorAction Ignore).Headers.Location
    $ProfilePath = Join-Path $env:TEMP ($ProfileModuleName + ".zip")
    $WebClient.DownloadFile($ProfileURL, $ProfilePath)

    # Download AzureRM.Automation to temp location
    $ModuleContentUrl = Get-ModuleContentUrl $AutomationModuleName
    $AutomationURL = (Invoke-WebRequest -Uri $ModuleContentUrl -MaximumRedirection 0 -UseBasicParsing -ErrorAction Ignore).Headers.Location
    $AutomationPath = Join-Path $env:TEMP ($AutomationModuleName + ".zip")
    $WebClient.DownloadFile($AutomationURL, $AutomationPath)

    # Create folder for unzipping the Module files
    $PathFolderName = New-Guid
    $PathFolder = Join-Path $env:TEMP $PathFolderName

    # Unzip files
    $ProfileUnzipPath = Join-Path $PathFolder $ProfileModuleName
    Expand-Archive -Path $ProfilePath -DestinationPath $ProfileUnzipPath -Force
    $AutomationUnzipPath = Join-Path $PathFolder $AutomationModuleName
    Expand-Archive -Path $AutomationPath -DestinationPath $AutomationUnzipPath -Force

    # Import modules
    Import-Module (Join-Path $ProfileUnzipPath ($ProfileModuleName + ".psd1")) -Force -Verbose
    Import-Module (Join-Path $AutomationUnzipPath ($AutomationModuleName + ".psd1")) -Force -Verbose
}

#endregion

#region Main body

if ($ModuleVersionOverrides) {
    $ModuleVersionOverridesHashTable = ConvertJsonDictTo-HashTable $ModuleVersionOverrides
} else {
    $ModuleVersionOverridesHashTable = @{}
}


$UseAzModule = $null
$AutomationModuleName = $null

# We want to support updating Az modules. This means this runbook should support upgrading using only Az modules
if ($AzureModuleClass -eq "Az") {
    $UseAzModule = $true
    $AutomationModuleName = $script:AzAutomationModuleName
} elseif ( $AzureModuleClass -eq "AzureRM") {
    $UseAzModule = $false
    $AutomationModuleName = $script:AzureRMAutomationModuleName
} else {
     Write-Error "Invalid AzureModuleClass: '$AzureModuleClass'. Must be either Az or AzureRM" -ErrorAction Stop
}

# Import the latest version of the Az automation and accounts version to the local sandbox
Update-ProfileAndAutomationVersionToLatest $AutomationModuleName

if ($Login) {
    Login-AzureAutomation $UseAzModule
}

$ModuleImportMapOrder = Create-ModuleImportMapOrder $UseAzModule
Import-ModulesInAutomationAccordingToDependency $ModuleImportMapOrder $UseAzModule


#endregion
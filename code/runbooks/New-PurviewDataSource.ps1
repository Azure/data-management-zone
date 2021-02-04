$Global:accessToken = $null
$Global:accessTokenExpiry = $null


function Get-AadToken {
    <#
    .SYNOPSIS
        Gets an AAD token for a registered AAD application.
    .DESCRIPTION
        Gets an AAD token for a registered AAD application. The application requires the following API permissions:
            * ...
    .PARAMETER TenantId
        Specifies the AAD tenant ID of the application.
    .PARAMETER ClientId
        Specifies the client ID of the application.
    .PARAMETER ClientSecret
        Specifies client secret of the application.
    .EXAMPLE
        Get-AadToken -TenantId '<your-tenant-id>' -ClientId '<your-client-id>' -ClientId '<your-client-secret>'
    .NOTES
        Author:  Marvin Buss
        GitHub:  @marvinbuss
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $TenantId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ClientId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ClientSecret
    )
    # Set Authority Host URL
    Write-Verbose "Setting Authority Host URL"
    $authorityHostUrl = "https://login.microsoftonline.com/${TenantId}/oauth2/token"

    # Set body for REST call
    Write-Verbose "Setting Body for REST API call"
    $body = @{
        'client_id'     = $ClientId
        'client_secret' = $ClientSecret
        'resource'      = '73c2949e-da2d-457a-9607-fcc665198967'
        'grant_type'    = 'client_credentials'
    }

    # Define parameters for REST method
    Write-Verbose "Defining parameters for pscore method"
    $parameters = @{
        'Uri'         = $authorityHostUrl
        'Method'      = 'Post'
        'Body'        = $body
        'ContentType' = 'application/x-www-form-urlencoded'
    }

    # Invoke REST API
    Write-Verbose "Invoking REST API"
    try {
        $response = Invoke-RestMethod @parameters
    }
    catch {
        Write-Host -ForegroundColor:Red $_
        Write-Host -ForegroundColor:Red "StatusCode:" $_.Exception.Response.StatusCode.value__
        Write-Host -ForegroundColor:Red "StatusDescription:" $_.Exception.Response.StatusDescription
        Write-Host -ForegroundColor:Red $_.Exception.Message
        throw "REST API call failed"
    }

    # Calculate Access Token Expiry
    $unixTime = (New-TimeSpan -Start (Get-Date "01/01/1970") -End (Get-Date -AsUTC)).TotalSeconds
    $accessTokenExpiry = $unixTime + $response.expires_in

    # Set global variables
    Write-Verbose "Setting global variables"
    Set-Variable -Name "accessToken" -Value $response.access_token -Scope global
    Set-Variable -Name "accessTokenExpiry" -Value $accessTokenExpiry -Scope global

    Write-Verbose "Access Token: ${Global:accessToken}"
    Write-Verbose "Access Token Expiry: ${Global:accessTokenExpiry}"
}


function Assert-Authentication {
    <#
    .SYNOPSIS
        Checks whether authentication was executed successfully.
    .DESCRIPTION
        The function checks whether authentication was successfully executed.
        The AAD token must exist and must be valid and not expired.
    .EXAMPLE
        Assert-Authentication
    .NOTES
        Author:  Marvin Buss
        GitHub:  @marvinbuss
    #>
    [CmdletBinding()]
    param ()
    # Get Unix time
    Write-Verbose "Getting Unix time"
    $unixTime = (New-TimeSpan -Start (Get-Date "01/01/1970") -End (Get-Date -AsUTC)).TotalSeconds

    # Check authentication
    Write-Verbose "Checking authentication"
    if ([string]::IsNullOrEmpty($Global:accessToken) -or [string]::IsNullOrEmpty($Global:accessTokenExpiry)) {
        # Not authenticated
        Write-Verbose "Please authenticate before invoking Microsoft Graph REST APIs"
        throw "Not authenticated"
        
    }
    elseif (($Global:accessTokenExpiry - $unixTime) -le 600) {
        # Access token expired
        Write-Verbose "Microsoft Access token expired"
        throw "Microsoft Access token expired"
    }
}


function New-PurviewKeyVaultConnection {
    <#
    .SYNOPSIS
        Gets an AAD token for a registered AAD application.
    .DESCRIPTION
        Gets an AAD token for a registered AAD application. The application requires the following API permissions:
            * ...
    .PARAMETER PurviewName
        Specifies the Name of the Purview Account.
    .PARAMETER KeyVaultId
        Specifies the Resource ID of the KeyVault that should be connected to the Purview Account.
    .EXAMPLE
        New-PurviewKeyVaultConnection -PurviewName '<your-purview-account-name>' -KeyVaultId '<your-keyvault-resource-id>'
    .NOTES
        Author:  Marvin Buss
        GitHub:  @marvinbuss
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $PurviewName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $KeyVaultId,

        [Parameter(DontShow)]
        [String]
        $ApiVersion = "2018-12-01-preview"
    )
    # Validate authentication
    Write-Verbose "Validating authentication"
    Assert-Authentication

    # Parse Variables
    Write-Verbose "Parsing Variables"
    $KeyVaultName = ($KeyVaultId -split "/")[-1]

    # Set Purview API URI
    Write-Verbose "Setting Graph API URI"
    $purviewApiUri = "https://${PurviewName}.scan.purview.azure.com/azureKeyVaults/${KeyVaultName}?api-version=${ApiVersion}"
    Write-Verbose $purviewApiUri

    # Set header for REST call
    Write-Verbose "Setting header for REST call"
    $headers = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer ${Global:accessToken}"
    }
    Write-Verbose $headers.values

    # Set body for REST call
    Write-Verbose "Setting body for REST call"
    $body = @{
        'name'       = "${KeyVaultName}"
        'properties' = @{
            'baseUrl'     = "https://${KeyVaultName}.vault.azure.net/"
            'description' = $KeyVaultName
        }
    } | ConvertTo-Json

    # Define parameters for REST method
    Write-Verbose "Defining parameters for pscore method"
    $parameters = @{
        'Uri'         = $purviewApiUri
        'Method'      = 'Put'
        'Headers'     = $headers
        'Body'        = $body
        'ContentType' = 'application/json'
    }

    # Invoke REST API
    Write-Verbose "Invoking REST API"
    try {
        $response = Invoke-RestMethod @parameters
        Write-Verbose "Response: ${response}"
    }
    catch {
        Write-Host -ForegroundColor:Red $_
        Write-Host -ForegroundColor:Red "StatusCode:" $_.Exception.Response.StatusCode.value__
        Write-Host -ForegroundColor:Red "StatusDescription:" $_.Exception.Response.StatusDescription
        Write-Host -ForegroundColor:Red $_.Exception.Message
        throw "REST API call failed"
    }
    return $response
}


function New-PurviewSubscriptionSource {
    <#
    .SYNOPSIS
        Registers a Subscription as a Data Source in the Purview Account.
    .DESCRIPTION
        Registers a Seubscription as a Data Source in your Purview Account. This allows then to scan all sources in this
        Azure Subscription. 
    .PARAMETER PurviewName
        Specifies the Name of the Purview Account.
    .PARAMETER SubscriptionId
        Specifies the Subscription ID of which all supported Data Sources should be registered in the Purview Account.
    .EXAMPLE
        New-PurviewSubscriptionSource -PurviewName '<your-purview-account-name>' -SubscriptionId '<your-subscription-id>'
    .NOTES
        Author:  Marvin Buss
        GitHub:  @marvinbuss
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $PurviewName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $SubscriptionId,

        [Parameter(DontShow)]
        [String]
        $ApiVersion = "2018-12-01-preview"
    )
    # Validate authentication
    Write-Verbose "Validating authentication"
    Assert-Authentication

    # Set Purview API URI
    Write-Verbose "Setting Graph API URI"
    $purviewApiUri = "https://${PurviewName}.scan.purview.azure.com/datasources/${SubscriptionId}?api-version=${ApiVersion}"
    Write-Verbose $purviewApiUri

    # Set header for REST call
    Write-Verbose "Setting header for REST call"
    $headers = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer ${Global:accessToken}"
    }
    Write-Verbose $headers.values

    # Set body for REST call
    Write-Verbose "Setting body for REST call"
    $body = @{
        'kind'       = 'AzureSubscription'
        'name'       = "${SubscriptionId}"
        'properties' = @{
            'subscriptionId' = "${SubscriptionId}"
        }
    } | ConvertTo-Json

    # Define parameters for REST method
    Write-Verbose "Defining parameters for pscore method"
    $parameters = @{
        'Uri'         = $purviewApiUri
        'Method'      = 'Put'
        'Headers'     = $headers
        'Body'        = $body
        'ContentType' = 'application/json'
    }

    # Invoke REST API
    Write-Verbose "Invoking REST API"
    try {
        $response = Invoke-RestMethod @parameters
        Write-Verbose "Response: ${response}"
    }
    catch {
        Write-Host -ForegroundColor:Red $_
        Write-Host -ForegroundColor:Red "StatusCode:" $_.Exception.Response.StatusCode.value__
        Write-Host -ForegroundColor:Red "StatusDescription:" $_.Exception.Response.StatusDescription
        Write-Host -ForegroundColor:Red $_.Exception.Message
        throw "REST API call failed"
    }
    return $response
}


function New-PurviewBlobSource {
    <#
    .SYNOPSIS
        Registers a Blob Storage Account as a Data Source in the Purview Account.
    .DESCRIPTION
        Registers a Blob Storage Account as a Data Source in your Purview Account. This allows then to scan the
        Resource in the respective subscription. 
    .PARAMETER PurviewName
        Specifies the Name of the Purview Account.
    .PARAMETER BlobStorageResourceId
        Specifies the Resource ID of the Blob Storage Account which should be registered in the Purview Account.
    .EXAMPLE
        New-PurviewBlobSource -PurviewName '<your-purview-account-name>' -BlobStorageResourceId '<your-blob-storage-resource-id>' -BlobStorageLocation '<your-blob-storage-location (e.g. 'westeurope')>'
    .NOTES
        Author:  Marvin Buss
        GitHub:  @marvinbuss
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $PurviewName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $BlobStorageResourceId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $BlobStorageLocation,

        [Parameter(DontShow)]
        [String]
        $ApiVersion = "2018-12-01-preview"
    )
    # Validate authentication
    Write-Verbose "Validating authentication"
    Assert-Authentication

    # Parse Variables
    Write-Verbose "Parsing Variables"
    $BlobStorageSubscriptionId = ($BlobStorageResourceId -split "/")[2]
    $BlobStorageResourceGroupName = ($BlobStorageResourceId -split "/")[4]
    $BlobStorageName = ($BlobStorageResourceId -split "/")[-1]

    # Set Purview API URI
    Write-Verbose "Setting Graph API URI"
    $purviewApiUri = "https://${PurviewName}.scan.purview.azure.com/datasources/${BlobStorageName}?api-version=${ApiVersion}"
    Write-Verbose $purviewApiUri

    # Set header for REST call
    Write-Verbose "Setting header for REST call"
    $headers = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer ${Global:accessToken}"
    }
    Write-Verbose $headers.values

    # Set body for REST call
    Write-Verbose "Setting body for REST call"
    $body = @{
        'kind'       = 'AzureStorage'
        'name'       = "${BlobStorageName}"
        'properties' = @{
            'endpoint'       = "https://${BlobStorageName}.blob.core.windows.net/"
            'location'       = "${BlobStorageLocation}"
            'resourceGroup'  = "${BlobStorageResourceGroupName}"
            'resourceName'   = "${BlobStorageName}"
            'subscriptionId' = "${BlobStorageSubscriptionId}"
        }
    } | ConvertTo-Json

    # Define parameters for REST method
    Write-Verbose "Defining parameters for pscore method"
    $parameters = @{
        'Uri'         = $purviewApiUri
        'Method'      = 'Put'
        'Headers'     = $headers
        'Body'        = $body
        'ContentType' = 'application/json'
    }

    # Invoke REST API
    Write-Verbose "Invoking REST API"
    try {
        $response = Invoke-RestMethod @parameters
        Write-Verbose "Response: ${response}"
    }
    catch {
        Write-Host -ForegroundColor:Red $_
        Write-Host -ForegroundColor:Red "StatusCode:" $_.Exception.Response.StatusCode.value__
        Write-Host -ForegroundColor:Red "StatusDescription:" $_.Exception.Response.StatusDescription
        Write-Host -ForegroundColor:Red $_.Exception.Message
        throw "REST API call failed"
    }
    return $response
}

# Authentication and get AAD Token
Write-Host "Logging in and getting AAD Token"
Get-AadToken `
    -TenantId $TenantId `
    -ClientId $ClientId `
    -ClientSecret $ClientSecret

# Add Key Vault Connection
Write-Host "Adding Key Vault Connection"
New-PurviewKeyVaultConnection `
    -PurviewName $PurviewName `
    -KeyVaultId $KeyVaultId

# Register Subscription Source
Write-Host "Registering Subscription Source"
New-PurviewSubscriptionSource `
    -PurviewName $PurviewName `
    -DataSourceName $DataSourceName `
    -SubscriptionId $SubscriptionId

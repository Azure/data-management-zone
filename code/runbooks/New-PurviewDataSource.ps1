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
        Registers a Subscription as a Data Source in your Purview Account. This allows then to scan all sources in this
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


function New-PurviewSubscriptionScan {
    <#
    .SYNOPSIS
        Tests Scan Connectivity to a registered Data Source in the Purview Account.
    .DESCRIPTION
        Tests Scan Connectivity to a registered Data Source in the Purview Account. If connectivity is not given, this function fails.
    .PARAMETER PurviewName
        Specifies the Name of the Purview Account.
    .PARAMETER PurviewDataSourceName
        Specifies the name of the data source in Purview for which the Scan Connectivity should be tested.
    .PARAMETER PurviewAuthenticationKind
        Specifies the Purview Authentication Kind which should be used for testing the Scan Connectivity.
    .PARAMETER PurviewCredentialType
        Specifies the Purview Credential Type which should be used for testing the Scan Connectivity.
    .PARAMETER PurviewCredentialReferenceName
        Specifies the Purview Credential Reference Name which should be used for testing the Scan Connectivity. This is the name of the secret in the referenced Key Vault.
    .PARAMETER TestConnection
        Specifies whether the Scan Connectivity should be just tested. If this option is selected, the Scan is not created. 
    .EXAMPLE
        New-PurviewDataSourceScan -PurviewName '<your-purview-account-name>' -PurviewDataSourceName '<your-purview-data-source-name>' -PurviewAuthenticationKind '<your-purview-authentication-kind>' -PurviewCredentialType '<your-purview-credential-type>' -PurviewCredentialReferenceName '<your-purview-credential-reference-name>' -TestConnection
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
        $PurviewDataSourceName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('AzureSubscriptionMsi')] # 'AzureSubscriptionCredential' not supported yet
        [String]
        $PurviewAuthenticationKind,

        [Parameter(Mandatory = $false)]
        [ValidateSet('AccountKey', 'ServicePrincipal', '', '', '', '', '', '')]
        [String]
        $PurviewCredentialType,

        [Parameter(Mandatory = $false)]
        [String]
        $PurviewCredentialReferenceName,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Custom', 'System')]
        [String]
        $PurviewScanRulesetType,

        [Parameter(Mandatory = $false)]
        [String]
        $PurviewScanRulesetName,

        [Parameter(DontShow)]
        [String]
        $ApiVersion = "2018-12-01-preview"
    )
    # Validate authentication
    Write-Verbose "Validating authentication"
    Assert-Authentication

    # Check Method
    Write-Verbose "Checking Method"
    if ($TestConnection) {
        $testConnectivity = '/testConnectivity'
        $method = 'Post'
    }
    else {
        $testConnectivity = ''
        $method = 'Put'
    }

    # Set Purview API URI
    Write-Verbose "Setting Graph API URI"
    $purviewApiUri = "https://${PurviewName}.scan.purview.azure.com/datasources/${PurviewDataSourceName}/scans/${PurviewDataSourceName}-Scan?api-version=${ApiVersion}"
    Write-Verbose $purviewApiUri

    # Set Header for REST call
    Write-Verbose "Setting header for REST call"
    $headers = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer ${Global:accessToken}"
    }
    Write-Verbose $headers.values
    
    # Set body for REST call
    Write-Verbose "Setting body for REST call"
    $body = @{
        'kind' = "${PurviewAuthenticationKind}"
        'name' = "${PurviewDataSourceName}-Scan"
        'properties' = @{
            'credential' = $null
            'resourceTypes' = @{
                ''
            }
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


function New-PurviewPowerBiSource {
    <#
    .SYNOPSIS
        Registers Power BI as a Data Source in the Purview Account.
    .DESCRIPTION
        Registers Power BI as a Data Source in your Purview Account. This allows then to scan all sources in this
        Power BI Account. 
    .PARAMETER PurviewName
        Specifies the Name of the Purview Account.
    .PARAMETER TenantId
        Specifies the Tenant ID of AAD.
    .EXAMPLE
        New-PurviewPowerBiSource -PurviewName '<your-purview-account-name>' -TenantId '<your-tenant-id>'
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
        $TenantId,

        [Parameter(DontShow)]
        [String]
        $ApiVersion = "2018-12-01-preview"
    )
    # Validate authentication
    Write-Verbose "Validating authentication"
    Assert-Authentication

    # Set Purview API URI
    Write-Verbose "Setting Graph API URI"
    $purviewApiUri = "https://${PurviewName}.scan.purview.azure.com/datasources/PowerBI?api-version=${ApiVersion}"
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
        'kind'       = 'PowerBI'
        'name'       = 'PowerBI'
        'properties' = @{
            'tenant' = "${TenantId}"
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


function New-PurviewDataSource {
    <#
    .SYNOPSIS
        Registers a Data Service of the specified Kind as a Data Source in the Purview Account.
    .DESCRIPTION
        Registers a Data Service of the specified Kind as a Data Source in your Purview Account. This allows then to scan the
        Resource in the respective subscription.
    .PARAMETER PurviewName
        Specifies the Name of the Purview Account.
    .PARAMETER DataServiceResourceId
        Specifies the Resource ID of the Data Service which should be registered in the Purview Account.
    .PARAMETER DataServiceLocation
        Specifies the Location of the Data Service that gets registered into the Purview Account.
    .PARAMETER SqlServerEndpoint
        Optional Parameter that specifies the SQL Server Endpoint. Can be one of the following:
            - <server name>
            - <server IP address>
            - <server name>,<port>
            - <server IP address>,<port>
            - <server name>\<instance> 
    .EXAMPLE
        New-PurviewDataSource -PurviewName '<your-purview-account-name>' -DataServiceResourceId '<your-data-service-resource-id>' -DataServiceLocation '<your-blob-storage-location (e.g. 'westeurope')>' -DataServiceKind '<your-data-service-kind>' -SqlServerEndpoint '<your-optional-sql-server-endpoint>'
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
        $DataServiceResourceId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $DataServiceLocation,

        [Parameter(Mandatory = $true)]
        [ValidateSet('AzureStorage', 'AzureCosmosDb', 'AzureDataExplorer', 'AdlsGen1', 'AdlsGen2', 'AzureSqlDatabase', 'AzureSqlDataWarehouse', 'SqlServerDatabase')]
        [String]
        $DataServiceKind,

        [Parameter(Mandatory = $false)]
        [String]
        $SqlServerEndpoint,

        [Parameter(DontShow)]
        [String]
        $ApiVersion = "2018-12-01-preview"
    )
    # Validate authentication
    Write-Verbose "Validating authentication"
    Assert-Authentication

    # Parse Variables
    Write-Verbose "Parsing Variables"
    $DataServiceSubscriptionId = ($DataServiceResourceId -split "/")[2]
    $DataServiceResourceGroupName = ($DataServiceResourceId -split "/")[4]
    $DataServiceName = ($DataServiceResourceId -split "/")[-1]

    # Set Purview API URI
    Write-Verbose "Setting Graph API URI"
    $purviewApiUri = "https://${PurviewName}.scan.purview.azure.com/datasources/${DataServiceName}?api-version=${ApiVersion}"
    Write-Verbose $purviewApiUri

    # Set Header for REST call
    Write-Verbose "Setting header for REST call"
    $headers = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer ${Global:accessToken}"
    }
    Write-Verbose $headers.values

    # Define Body Properties
    Write-Verbose "Defining Body Properties"
    if ($DataServiceKind -eq 'AzureStorage') {
        $properties = @{
            'endpoint'       = "https://${DataServiceName}.blob.core.windows.net/"
            'location'       = "${DataServiceLocation}"
            'resourceGroup'  = "${DataServiceResourceGroupName}"
            'resourceName'   = "${DataServiceName}"
            'subscriptionId' = "${DataServiceSubscriptionId}"
            # 'parentCollection' = @{
            #     'type' = 'DataSourceReference'
            #     'referenceName' = "${DataSourceCollectionName}"
            # }
        }
    }
    elseif ($DataServiceKind -eq 'AzureCosmosDb') {
        $properties = @{
            'accountUri'     = "https://${DataServiceName}.documents.azure.com:443/"
            'location'       = "${DataServiceLocation}"
            'resourceGroup'  = "${DataServiceResourceGroupName}"
            'resourceName'   = "${DataServiceName}"
            'subscriptionId' = "${DataServiceSubscriptionId}"
        }
    }
    elseif ($DataServiceKind -eq 'AzureDataExplorer') {
        $properties = @{
            'endpoint'       = "https://${DataServiceName}.${DataServiceLocation}.kusto.windows.net"
            'location'       = "${DataServiceLocation}"
            'resourceGroup'  = "${DataServiceResourceGroupName}"
            'resourceName'   = "${DataServiceName}"
            'subscriptionId' = "${DataServiceSubscriptionId}"
        }
    }
    elseif ($DataServiceKind -eq 'AdlsGen1') {
        $properties = @{
            'endpoint'       = "https://${DataServiceName}.azuredatalakestore.net/webhdfs/v1/"
            'location'       = "${DataServiceLocation}"
            'resourceGroup'  = "${DataServiceResourceGroupName}"
            'resourceName'   = "${DataServiceName}"
            'subscriptionId' = "${DataServiceSubscriptionId}"
        }
    }
    elseif ($DataServiceKind -eq 'AdlsGen2') {
        $properties = @{
            'endpoint'       = "https://${DataServiceName}.dfs.core.windows.net/"
            'location'       = "${DataServiceLocation}"
            'resourceGroup'  = "${DataServiceResourceGroupName}"
            'resourceName'   = "${DataServiceName}"
            'subscriptionId' = "${DataServiceSubscriptionId}"
        }
    }
    elseif ($DataServiceKind -eq 'AzureSqlDatabase') {
        $properties = @{
            'serverEndpoint' = "${DataServiceName}.database.windows.net"
            'location'       = "${DataServiceLocation}"
            'resourceGroup'  = "${DataServiceResourceGroupName}"
            'resourceName'   = "${DataServiceName}"
            'subscriptionId' = "${DataServiceSubscriptionId}"
        }
    }
    elseif ($DataServiceKind -eq 'AzureSqlDataWarehouse') {
        $properties = @{
            'serverEndpoint' = "${DataServiceName}.database.windows.net"
            'location'       = "${DataServiceLocation}"
            'resourceGroup'  = "${DataServiceResourceGroupName}"
            'resourceName'   = "${DataServiceName}"
            'subscriptionId' = "${DataServiceSubscriptionId}"
        }
    }
    elseif ($DataServiceKind -eq 'SqlServerDatabase') {
        $properties = @{
            'serverEndpoint' = "${SqlServerEndpoint}"
        }
    }

    # Set body for REST call
    Write-Verbose "Setting body for REST call"
    $body = @{
        'kind'       = "${DataServiceKind}"
        'name'       = "${DataServiceName}"
        'properties' = $properties
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


function New-PurviewDataSourceScan {
    <#
    .SYNOPSIS
        Tests Scan Connectivity to a registered Data Source in the Purview Account.
    .DESCRIPTION
        Tests Scan Connectivity to a registered Data Source in the Purview Account. If connectivity is not given, this function fails.
    .PARAMETER PurviewName
        Specifies the Name of the Purview Account.
    .PARAMETER PurviewDataSourceName
        Specifies the name of the data source in Purview for which the Scan Connectivity should be tested.
    .PARAMETER PurviewAuthenticationKind
        Specifies the Purview Authentication Kind which should be used for testing the Scan Connectivity.
    .PARAMETER PurviewCredentialType
        Specifies the Purview Credential Type which should be used for testing the Scan Connectivity.
    .PARAMETER PurviewCredentialReferenceName
        Specifies the Purview Credential Reference Name which should be used for testing the Scan Connectivity. This is the name of the secret in the referenced Key Vault.
    .PARAMETER TestConnection
        Specifies whether the Scan Connectivity should be just tested. If this option is selected, the Scan is not created. 
    .EXAMPLE
        New-PurviewDataSourceScan -PurviewName '<your-purview-account-name>' -PurviewDataSourceName '<your-purview-data-source-name>' -PurviewAuthenticationKind '<your-purview-authentication-kind>' -PurviewCredentialType '<your-purview-credential-type>' -PurviewCredentialReferenceName '<your-purview-credential-reference-name>' -TestConnection
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
        $PurviewDataSourceName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('AzureStorageMsi', 'AzureStorageCredential', '', '', '', '', '', '')]
        [String]
        $PurviewAuthenticationKind,

        [Parameter(Mandatory = $false)]
        [ValidateSet('AccountKey', 'ServicePrincipal', '', '', '', '', '', '')]
        [String]
        $PurviewCredentialType,

        [Parameter(Mandatory = $false)]
        [String]
        $PurviewCredentialReferenceName,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Custom', 'System')]
        [String]
        $PurviewScanRulesetType,

        [Parameter(Mandatory = $false)]
        [String]
        $PurviewScanRulesetName,

        [Parameter(Mandatory = $false)]
        [Switch]
        $TestConnection,

        [Parameter(DontShow)]
        [String]
        $ApiVersion = "2018-12-01-preview"
    )
    # Validate authentication
    Write-Verbose "Validating authentication"
    Assert-Authentication

    # Check Method
    Write-Verbose "Checking Method"
    if ($TestConnection) {
        $testConnectivity = '/testConnectivity'
        $method = 'Post'
    }
    else {
        $testConnectivity = ''
        $method = 'Put'
    }

    # Set Purview API URI
    Write-Verbose "Setting Graph API URI"
    $purviewApiUri = "https://${PurviewName}.scan.purview.azure.com/datasources/${PurviewDataSourceName}/scans/${PurviewDataSourceName}-Scan${testConnectivity}?api-version=${ApiVersion}"
    Write-Verbose $purviewApiUri

    # Set Header for REST call
    Write-Verbose "Setting header for REST call"
    $headers = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer ${Global:accessToken}"
    }
    Write-Verbose $headers.values

    # Define Body Properties
    Write-Verbose "Defining Body Properties"
    if ($DataServiceKind -eq 'AzureStorageMsi') {
        $properties = @{
            'credential' = $null
            'scanRulesetType' = "${PurviewScanRulesetType}"
            'scanRulesetName' = "${PurviewScanRulesetName}"
        }
    }
    elseif ($DataServiceKind -eq 'AzureStorageCredential') {
        $properties = @{
            'credential' = @{
                'credentialType' = "${PurviewCredentialType}"
                'referenceName'  = "${PurviewCredentialReferenceName}"
            }
            'scanRulesetType' = "${PurviewScanRulesetType}"
            'scanRulesetName' = "${PurviewScanRulesetName}"
        }
    }
    
    # Set body for REST call
    Write-Verbose "Setting body for REST call"
    $body = @{
        'scan' = @{
            'kind'       = "${$PurviewAuthenticationKind}"
            'name'       = "${PurviewDataSourceName}-Scan"
            'properties' = $properties
        }
    } | ConvertTo-Json

    # Define parameters for REST method
    Write-Verbose "Defining parameters for pscore method"
    $parameters = @{
        'Uri'         = $purviewApiUri
        'Method'      = $method
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


function New-PurviewDataSourceScanTrigger {
    <#
    .SYNOPSIS
        Registers a Data Service of the specified Kind as a Data Source in the Purview Account.
    .DESCRIPTION
        Registers a Data Service of the specified Kind as a Data Source in your Purview Account. This allows then to scan the
        Resource in the respective subscription.
    .PARAMETER PurviewName
        Specifies the Name of the Purview Account.
    .PARAMETER PurviewDataSourceName
        Specifies the name of the data source in Purview for which the Scan Connectivity should be tested.
    .PARAMETER PurviewDataScanName
        Specifies the name of the Scan for the Data Source in Purview.
    .PARAMETER ScanFrequency
        Specifies the Scan Frequency that should be used for triggering the scan.
    .PARAMETER ScanInterval
        Specifies the Interval for when the scan should be triggered.
    .PARAMETER ScanHours
        Specifies the Hours for when the scan should be triggered.
    .PARAMETER ScanMinutes
        Specifies the Minutes for when the scan should be triggered.
    .PARAMETER ScanWeekDays
        Specifies the Weeksdays for when the scan should be triggered.
    .EXAMPLE
        New-PurviewDataSourceScanTrigger -PurviewName '<your-purview-account-name>' -PurviewDataSourceName '<your-purview-data-source-name>' -PurviewDataScanName '<your-purview-scan-name>' -ScanFrequency '<your-purview-scan-frequency>' -ScanInterval '<your-purview-scan-interval>' -ScanHours '<your-purview-scan-hours>' -ScanMinutes '<your-purview-scan-minutes>' -ScanWeekDays '<your-purview-scan-weekdays>'
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
        $PurviewDataSourceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $PurviewDataScanName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Week', 'Month')]
        [String]
        $ScanFrequency,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Int32]
        $ScanInterval,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Int32[]]
        $ScanHours,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Int32[]]
        $ScanMinutes,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $ScanWeekDays,

        [Parameter(DontShow)]
        [String]
        $ApiVersion = "2018-12-01-preview"
    )
    # Validate authentication
    Write-Verbose "Validating authentication"
    Assert-Authentication

    # Set Purview API URI
    Write-Verbose "Setting Graph API URI"
    $purviewApiUri = "https://${PurviewName}.scan.purview.azure.com/datasources/${PurviewDataSourceName}/scans/${PurviewDataScanName}/triggers/default?api-version=${ApiVersion}"
    Write-Verbose $purviewApiUri

    # Set Header for REST call
    Write-Verbose "Setting header for REST call"
    $headers = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer ${Global:accessToken}"
    }
    Write-Verbose $headers.values

    # Set body for REST call
    Write-Verbose "Setting body for REST call"
    $time = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
    $body = @{
        'name' = 'default'
        'properties' = @{
            'recurrence' = @{
                'frequency' = "${ScanFrequency}"
                'interval' = $ScanInterval
                'schedule' = @{
                    'hours' = $ScanHours
                    'minutes' = $ScanMinutes
                    'weekDays' = $ScanWeekDays
                }
                'startTime' = $time
            }
            'recurrenceInterval' = $null
            'scanLevel' = 'Incremental'
        }
    } | ConvertTo-Json

    # Define parameters for REST method
    Write-Verbose "Defining parameters for pscore method"
    $parameters = @{
        'Uri'         = $purviewApiUri
        'Method'      = 'Post'
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
    -SubscriptionId $SubscriptionId

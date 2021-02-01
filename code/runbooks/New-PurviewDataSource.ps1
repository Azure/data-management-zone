
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
    $authorityHostUrl = "https://login.microsoftonline.com/${TenantId}/oauth2/v2.0/token"

    # Set body for REST call
    Write-Verbose "Setting Body for REST API call"
    $body = @{
        'tenantId'      = $TenantId
        'client_id'     = $ClientId
        'client_secret' = $ClientSecret
        'scope'         = 'https://graph.microsoft.com/.default'
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


function New-PurviewSubscriptionSource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $PurviewName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $DataSourceName,

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
    $purviewApiUri = "https://${PurviewName}.scan.purview.azure.com/datasources/${DataSourceName}?api-version=${ApiVersion}"
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
        'name'       = "${DataSourceName}"
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


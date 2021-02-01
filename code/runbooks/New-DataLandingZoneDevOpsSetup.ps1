[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]
    $OrgName,

    [Parameter(Mandatory = $true)]
    [String]
    $SourceProjectName,

    [Parameter(Mandatory = $true)]
    [String]
    $SourceRepositoryName,

    [Parameter(Mandatory = $true)]
    [String]
    $DestinationProjectName,

    [Parameter(Mandatory = $true)]
    [String]
    $DestinationRepositoryName,

    [Parameter(Mandatory = $true)]
    [String]
    $PatToken,

    [Parameter(Position = 1, ValueFromRemainingArguments)]
    $Remaining
)


function Invoke-DevOpsApiRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $PatToken,

        [Parameter(Mandatory = $true)]
        [String]
        $RestMethod,

        [Parameter(Mandatory = $true)]
        [String]
        $UriExtension,

        [Parameter(Mandatory = $true)]
        [String]
        $Body,

        [Parameter(Mandatory = $true)]
        [String]
        $ApiVersion
    )
    # Define Endpoint Uri
    Write-Host "Defining Endpoint Uri"
    $devOpsApiUri = "https://dev.azure.com/${UriExtension}?api-version=${ApiVersion}"
    Write-Verbose "Endpoint URI: ${devOpsApiUri}"

    # Define Header for REST call
    Write-Verbose "Defining Header for REST call"
    $base64PatToken = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PatToken)"))
    $headers = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Basic ${base64PatToken}"
    }
    Write-Verbose $headers.values

    # Define parameters for REST method
    Write-Verbose "Defining parameters for pscore method"
    $parameters = @{
        'Uri'         = $devOpsApiUri
        'Method'      = $RestMethod
        'Headers'     = $headers
        'Body'        = $Body
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
    return $result
}


function Get-ProjectId {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $ProjectName,

        [Parameter(Mandatory = $true)]
        [String]
        $PatToken,

        [Parameter(Mandatory = $true)]
        [String]
        $OrgName
    )
    # Define URI Extension
    Write-Verbose "Defining URI Extension"
    $uriExtension = "${OrgName}/_apis/projects"

    # Define Body
    Write-Verbose "Defining Body"
    $body = @{} | ConvertTo-Json -Depth 5

    # Call REST API
    Write-Verbose "Calling REST API"
    $result = Invoke-DevOpsApiRequest -PatToken $PatToken -RestMethod Get -UriExtension $uriExtension -Body $body -ApiVersion "6.0"

    # Iterate through Projects and return ID
    Write-Verbose "Iterating through Projects and returning ID"
    foreach ($project in $result.value) {
        if ($project.name -eq $ProjectName) {
            return $project.id
        }
    }
    return $null
}


function Get-RepositoryId {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $RepositoryName,

        [Parameter(Mandatory = $true)]
        [String]
        $ProjectId,

        [Parameter(Mandatory = $true)]
        [String]
        $PatToken,

        [Parameter(Mandatory = $true)]
        [String]
        $OrgName
    )
    # Define URI Extension
    Write-Verbose "Defining URI Extension"
    $uriExtension = "${OrgName}/${ProjectId}/_apis/git/repositories"

    # Define Body
    Write-Verbose "Defining Body"
    $body = @{} | ConvertTo-Json -Depth 5

    # Call REST API
    Write-Verbose "Calling REST API"
    $result = Invoke-DevOpsApiRequest -PatToken $PatToken -RestMethod Get -UriExtension $uriExtension -Body $body -ApiVersion "6.0"

    # Iterate through Repositories and return ID
    Write-Verbose "Iterating through Repositories and return ID"
    foreach ($repository in $result.value) {
        if ($repository.name -eq $RepositoryName) {
            return $repository.id
        }
    }
}


function Add-Fork {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $SourceRepositoryId,

        [Parameter(Mandatory = $true)]
        [String]
        $SourceProjectId,

        [Parameter(Mandatory = $true)]
        [String]
        $DestinationRepositoryName,

        [Parameter(Mandatory = $true)]
        [String]
        $DestinationProjectId,

        [Parameter(Mandatory = $true)]
        [String]
        $PatToken,

        [Parameter(Mandatory = $true)]
        [String]
        $OrgName
    )
    # Define URI Extension
    Write-Verbose "Defining URI Extension"
    $uriExtension = "${OrgName}/_apis/git/repositories"

    # Define Body
    Write-Verbose "Defining Body"
    $body = @{
        "name" = $DestinationRepositoryName
        "project" = @{
            "id" = $DestinationProjectId
        }
        "parentRepository" = @{
            "id" = $SourceRepositoryId
            "project" = @{
                "id" = $SourceProjectId
            }
        }
    } | ConvertTo-Json -Depth 5

    # Call REST API
    Write-Verbose "Calling REST API"
    $result = Invoke-DevOpsApiRequest -PatToken $PatToken -RestMethod Post -UriExtension $uriExtension -Body $body -ApiVersion "6.0"
    return $result
}


function Add-Pipeline {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $DestinationProjectId,

        [Parameter(Mandatory = $true)]
        [String]
        $DestinationRepositoryId,

        [Parameter(Mandatory = $true)]
        [String]
        $DestinationRepositoryName,

        [Parameter(Mandatory = $true)]
        [String]
        $PatToken,

        [Parameter(Mandatory = $true)]
        [String]
        $OrgName
    )
    # Define URI Extension
    Write-Verbose "Defining URI Extension"
    $uriExtension = "${OrgName}/${DestinationProjectId}/_apis/pipelines"

    # Define Body
    Write-Verbose "Defining Body"
    $triggers = New-Object System.Collections.ArrayList
    $triggers.Add(@{"settingsSourceType" = 2; "triggerType" = 2;})
    $body = @{
        "name" = "${DestinationRepositoryName}-NodeDeployment"
        "folder" = "\\"
        "configuration" = @{
            "path" = ".ado/workflows/dataDomainDeployment.yml"
            "repository" = @{
                "id" = $DestinationRepositoryId
                "name" = $DestinationRepositoryName
                "type" = "azureReposGit"
            }
            "type" = "yaml"
            "triggers" = $triggers
        }
    } | ConvertTo-Json -Depth 5

    # Call REST API
    Write-Verbose "Calling REST API"
    $result = Invoke-DevOpsApiRequest -PatToken $PatToken -RestMethod Post -UriExtension $uriExtension -Body $body -ApiVersion "6.0-preview"
    return $result
}


function Add-PipelineRun {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $DestinationProjectId,

        [Parameter(Mandatory = $true)]
        [String]
        $PipelineId,

        [Parameter(Mandatory = $true)]
        [String]
        $PatToken,

        [Parameter(Mandatory = $true)]
        [String]
        $OrgName
    )
    # Define URI Extension
    Write-Verbose "Defining URI Extension"
    $uriExtension = "${OrgName}/${DestinationProjectId}/_apis/pipelines/${PipelineId}/runs"

    # Define Body
    Write-Verbose "Defining Body"
    $body = @{
        "previewRun" = $false
    } | ConvertTo-Json -Depth 5

    # Call REST API
    Write-Verbose "Calling REST API"
    $result = Invoke-DevOpsApiRequest -PatToken $PatToken -RestMethod Post -UriExtension $uriExtension -Body $body -ApiVersion "6.0-preview.1"
    return $result
}

function Update-Repository {
    [CmdletBinding()]
    param (
        
    )
    # git clone ""
}


# Get Project IDs and Repository IDs
Write-Host "Getting Project IDs and Repository IDs"
$sourceProjectId = Get-ProjectId -ProjectName $SourceProjectName -PatToken $PatToken -OrgName $OrgName
$destinationProjectId = Get-ProjectId -ProjectName $DestinationProjectName -PatToken $PatToken -OrgName $OrgName
$sourceRepositoryId = Get-RepositoryId -RepositoryName $SourceRepositoryName -ProjectId $sourceProjectId -PatToken $PatToken -OrgName $OrgName

# Fork Repository
Write-Host "Fork Repository"
$result = Add-Fork -SourceRepositoryId $sourceRepositoryId -SourceProjectId $sourceProjectId -DestinationProjectId $destinationProjectId -DestinationRepositoryName $DestinationRepositoryName -PatToken $PatToken -OrgName $OrgName
Write-Verbose "Result from Forking the Repository: ${result}"

# Sleep for X Seconds to give the DevOps Backend Process some time to Finish
$seconds = 5
Write-Host "Sleeping for ${seconds} Seconds to give the DevOps Backend Process some time to Finish"
Start-Sleep -Seconds $seconds

# Get Repository ID of Fork
Write-Host "Getting Repository ID of Fork"
$destinationRepositoryId = Get-RepositoryId -RepositoryName $DestinationRepositoryName -ProjectId $destinationProjectId -PatToken $PatToken -OrgName $OrgName

# TODO: Update Parameter values (JSON and YAML)

# Create Pipeline in Fork
Write-Host "Creating Pipeline in Fork"
$result = Add-Pipeline -DestinationProjectId $destinationProjectId -DestinationRepositoryId $destinationRepositoryId -DestinationRepositoryName $DestinationRepositoryName -OrgName $OrgName -PatToken $PatToken
$pipelineId = $result.id

# # Trigger pipeline
# Write-Host "Triggering Pipeline"
# $result = Add-PipelineRun -DestinationProjectId $destinationProjectId -PipelineId $pipelineId -OrgName $OrgName -PatToken $PatToken
# Write-Verbose $result

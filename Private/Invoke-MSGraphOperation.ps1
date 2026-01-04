function Invoke-MSGraphOperation {
    <#
    .SYNOPSIS
        Perform a specific call to Intune Graph API, either as GET, POST, PATCH or DELETE methods.
        
    .DESCRIPTION
        Perform a specific call to Intune Graph API, either as GET, POST, PATCH or DELETE methods.
        This function handles nextLink objects including throttling based on retry-after value from Graph response.
        
    .PARAMETER Get
        Switch parameter used to specify the method operation as 'GET'.
        
    .PARAMETER Post
        Switch parameter used to specify the method operation as 'POST'.
        
    .PARAMETER Patch
        Switch parameter used to specify the method operation as 'PATCH'.
        
    .PARAMETER Put
        Switch parameter used to specify the method operation as 'PUT'.
        
    .PARAMETER Delete
        Switch parameter used to specify the method operation as 'DELETE'.
        
    .PARAMETER Resource
        Specify the full resource path, e.g. deviceManagement/auditEvents.
        
    .PARAMETER Body
        Specify the body construct.
        
    .PARAMETER APIVersion
        Specify to use either 'Beta' or 'v1.0' API version.
        
    .PARAMETER ContentType
        Specify the content type for the graph request.
        
    .NOTES
        Author:      Nickolaj Andersen & Jan Ketil Skanke
        Contact:     @JankeSkanke @NickolajA
        Created:     2020-10-11
        Updated:     2026-01-04

        Version history:
        1.0.0 - (2020-10-11) Function created
        1.0.1 - (2020-11-11) Tested and verified for rate-limit and nextLink
        1.0.2 - (2021-04-12) Adjusted for usage in MSGraphRequest module
        1.0.3 - (2021-08-19) Fixed bug to handle single result
        1.0.4 - (2021-09-08) Added cross platform support for error details and fixed an error where StreamReader was used but not supported on newer PS versions.
                             Fixed bug to handle empty results when using GET operation.
        1.0.5 - (2026-01-04) Added sophisticated retry logic with exponential backoff, Retry-After header support, and transient error handling.
        1.0.6 - (2026-01-04) Implemented automatic token refresh using Update-AccessTokenFromRefreshToken when token expires.
                             Supports up to 10 retry attempts with intelligent delay calculation based on Graph API throttling responses.
    #>    
    param(
        [parameter(Mandatory = $true, ParameterSetName = "GET", HelpMessage = "Switch parameter used to specify the method operation as 'GET'.")]
        [switch]$Get,

        [parameter(Mandatory = $true, ParameterSetName = "POST", HelpMessage = "Switch parameter used to specify the method operation as 'POST'.")]
        [switch]$Post,

        [parameter(Mandatory = $true, ParameterSetName = "PATCH", HelpMessage = "Switch parameter used to specify the method operation as 'PATCH'.")]
        [switch]$Patch,

        [parameter(Mandatory = $true, ParameterSetName = "PUT", HelpMessage = "Switch parameter used to specify the method operation as 'PUT'.")]
        [switch]$Put,

        [parameter(Mandatory = $true, ParameterSetName = "DELETE", HelpMessage = "Switch parameter used to specify the method operation as 'DELETE'.")]
        [switch]$Delete,

        [parameter(Mandatory = $true, ParameterSetName = "GET", HelpMessage = "Specify the full resource path, e.g. deviceManagement/auditEvents.")]
        [parameter(Mandatory = $true, ParameterSetName = "POST")]
        [parameter(Mandatory = $true, ParameterSetName = "PATCH")]
        [parameter(Mandatory = $true, ParameterSetName = "PUT")]
        [parameter(Mandatory = $true, ParameterSetName = "DELETE")]
        [ValidateNotNullOrEmpty()]
        [string]$Resource,

        [parameter(Mandatory = $true, ParameterSetName = "POST", HelpMessage = "Specify the body construct.")]
        [parameter(Mandatory = $true, ParameterSetName = "PATCH")]
        [parameter(Mandatory = $true, ParameterSetName = "PUT")]
        [ValidateNotNullOrEmpty()]
        [System.Object]$Body,

        [parameter(Mandatory = $false, ParameterSetName = "GET", HelpMessage = "Specify to use either 'Beta' or 'v1.0' API version.")]
        [parameter(Mandatory = $false, ParameterSetName = "POST")]
        [parameter(Mandatory = $false, ParameterSetName = "PATCH")]
        [parameter(Mandatory = $false, ParameterSetName = "PUT")]
        [parameter(Mandatory = $false, ParameterSetName = "DELETE")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Beta", "v1.0")]
        [string]$APIVersion = "v1.0",

        [parameter(Mandatory = $false, ParameterSetName = "GET", HelpMessage = "Specify the content type for the graph request.")]
        [parameter(Mandatory = $false, ParameterSetName = "POST")]
        [parameter(Mandatory = $false, ParameterSetName = "PATCH")]
        [parameter(Mandatory = $false, ParameterSetName = "PUT")]
        [parameter(Mandatory = $false, ParameterSetName = "DELETE")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("application/json", "image/png")]
        [string]$ContentType = "application/json"
    )
    Begin {
        # Check if authentication header exists
        if ($Global:AuthenticationHeader -eq $null) {
            Write-Warning -Message "Unable to find authentication header, use Connect-MSIntuneGraph function before running this function"; break
        }

        # Check if access token needs refresh
        if (-not (Test-AccessToken)) {
            Write-Verbose -Message "Access token requires renewal"
            
            # Attempt silent refresh if refresh token is available
            if ($null -ne $Global:AccessToken -and $Global:AccessToken.PSObject.Properties["RefreshToken"] -and -not [string]::IsNullOrEmpty($Global:AccessToken.RefreshToken)) {
                Write-Verbose -Message "Attempting silent token refresh"
                try {
                    $Scopes = if ($Global:AccessToken.PSObject.Properties["Scopes"]) { $Global:AccessToken.Scopes } else { @("DeviceManagementApps.ReadWrite.All", "DeviceManagementRBAC.Read.All") }
                    Update-AccessTokenFromRefreshToken -TenantID $Global:AccessTokenTenantID -ClientID $Global:AccessToken.client_id -RefreshToken $Global:AccessToken.RefreshToken -Scopes $Scopes
                    
                    # Update authentication header with new token
                    $Global:AuthenticationHeader = New-AuthenticationHeader -AccessToken $Global:AccessToken
                    Write-Verbose -Message "Successfully refreshed access token silently"
                }
                catch {
                    Write-Warning -Message "Silent token refresh failed: $($_). Please re-authenticate using Connect-MSIntuneGraph"
                    break
                }
            }
            else {
                Write-Warning -Message "Access token has expired and no refresh token is available. Please re-authenticate using Connect-MSIntuneGraph"
                break
            }
        }

        # Retry parameters for transient error handling
        $MaxRetryAttempts = 10
        $RetryDelayRange = @{ Min = 5; Max = 30 }
    }
    Process {
        # Construct list as return value for handling both single and multiple instances in response from call
        $GraphResponseList = New-Object -TypeName "System.Collections.ArrayList"

        # Construct full URI
        $GraphURI = "https://graph.microsoft.com/$($APIVersion)/$($Resource)"
        Write-Verbose -Message "$($PSCmdlet.ParameterSetName) $($GraphURI)"        

        # Call Graph API and get JSON response with pagination and retry support
        $GraphResponseProcess = $true
        do {
            $RetryAttempt = 0
            $RequestSucceeded = $false

            while (-not $RequestSucceeded -and $RetryAttempt -lt $MaxRetryAttempts) {
                try {
                    # Construct table of default request parameters
                    $RequestParams = @{
                        "Uri" = $GraphURI
                        "Headers" = $Global:AuthenticationHeader
                        "Method" = $PSCmdlet.ParameterSetName
                        "ErrorAction" = "Stop"
                        "Verbose" = $false
                    }

                    switch ($PSCmdlet.ParameterSetName) {
                        "POST" {
                            $RequestParams.Add("Body", $Body)
                            $RequestParams.Add("ContentType", $ContentType)
                        }
                        "PATCH" {
                            $RequestParams.Add("Body", $Body)
                            $RequestParams.Add("ContentType", $ContentType)
                        }
                        "PUT" {
                            $RequestParams.Add("Body", $Body)
                            $RequestParams.Add("ContentType", $ContentType)
                        }
                    }

                    # Invoke Graph request
                    $GraphResponse = Invoke-RestMethod @RequestParams

                    # Mark request as successful
                    $RequestSucceeded = $true

                    # Handle paging in response
                    if ($GraphResponse.'@odata.nextLink' -ne $null) {
                        $GraphResponseList.AddRange($GraphResponse.value) | Out-Null
                        $GraphURI = $GraphResponse.'@odata.nextLink'
                        Write-Verbose -Message "NextLink: $($GraphURI)"
                    }
                    else {
                        # NextLink from response was null, assuming last page but also handle if a single instance is returned
                        if ($GraphResponse.value) {
                            $GraphResponseList.AddRange($GraphResponse.value) | Out-Null
                        }
                        elseif ($GraphResponse.'@odata.count' -eq 0)  {
                            # Do nothing to return empty
                        }
                        else {
                            $GraphResponseList.Add($GraphResponse) | Out-Null
                        }

                        # Set graph response as handled and stop processing loop
                        $GraphResponseProcess = $false
                    }
                }
                catch [System.Exception] {
                    # Capture current error
                    $ExceptionItem = $PSItem
                    $RetryAttempt++

                    # Determine if this is a retryable error
                    $IsRetryable = $false
                    $RetryDelay = 0
                    $UseExponentialBackoff = $false

                    # Construct response error custom object for cross platform support
                    $ResponseBody = [PSCustomObject]@{
                        "ErrorMessage" = [string]::Empty
                        "ErrorCode" = [string]::Empty
                    }

                    # Read response error details differently depending PSVersion
                    switch ($PSVersionTable.PSVersion.Major) {
                        "5" {
                            # Read the response stream
                            if ($ExceptionItem.Exception.Response) {
                                $StreamReader = New-Object -TypeName "System.IO.StreamReader" -ArgumentList @($ExceptionItem.Exception.Response.GetResponseStream())
                                $StreamReader.BaseStream.Position = 0
                                $StreamReader.DiscardBufferedData()
                                $ResponseContent = $StreamReader.ReadToEnd()

                                # Attempt to parse response as JSON
                                try {
                                    $ResponseReader = $ResponseContent | ConvertFrom-Json
                                    $ResponseBody.ErrorMessage = if ($ResponseReader.error.message) { $ResponseReader.error.message } else { $ResponseContent }
                                    $ResponseBody.ErrorCode = if ($ResponseReader.error.code) { $ResponseReader.error.code } else { "Unknown" }
                                }
                                catch {
                                    # Fallback for non-JSON responses
                                    Write-Verbose -Message "Failed to parse error response as JSON, using raw content"
                                    $ResponseBody.ErrorMessage = $ResponseContent
                                    $ResponseBody.ErrorCode = "JsonParseError"
                                }
                            }
                            else {
                                $ResponseBody.ErrorMessage = $ExceptionItem.Exception.Message
                                $ResponseBody.ErrorCode = "Unknown"
                            }
                        }
                        default {
                            # Validate and parse error details for PowerShell 6+
                            if ($ExceptionItem.ErrorDetails.Message -and (Test-Json -Json $ExceptionItem.ErrorDetails.Message -ErrorAction SilentlyContinue)) {
                                try {
                                    $ErrorDetails = $ExceptionItem.ErrorDetails.Message | ConvertFrom-Json
                                    $ResponseBody.ErrorMessage = if ($ErrorDetails.error.message) { $ErrorDetails.error.message } else { $ExceptionItem.ErrorDetails.Message }
                                    $ResponseBody.ErrorCode = if ($ErrorDetails.error.code) { $ErrorDetails.error.code } else { "Unknown" }
                                }
                                catch {
                                    # Fallback if JSON parsing fails despite validation
                                    Write-Verbose -Message "Failed to parse error response as JSON, using raw content"
                                    $ResponseBody.ErrorMessage = $ExceptionItem.ErrorDetails.Message
                                    $ResponseBody.ErrorCode = "JsonParseError"
                                }
                            }
                            else {
                                # Not valid JSON or null/empty, use raw error message
                                Write-Verbose -Message "Error response is not valid JSON or is empty"
                                $ResponseBody.ErrorMessage = if ($ExceptionItem.ErrorDetails.Message) { 
                                    $ExceptionItem.ErrorDetails.Message 
                                }
                                else { 
                                    $ExceptionItem.Exception.Message 
                                }
                                $ResponseBody.ErrorCode = "NonJsonError"
                            }
                        }
                    }

                    # Check for HTTP status code based retries (throttling, service issues)
                    if ($ExceptionItem.Exception.Response.StatusCode) {
                        $StatusCode = $ExceptionItem.Exception.Response.StatusCode

                        switch ($StatusCode) {
                            "TooManyRequests" {
                                # 429 - Use Retry-After header from Graph API (required by API specification)
                                $RetryAfterHeader = $ExceptionItem.Exception.Response.Headers["Retry-After"]
                                
                                if ($RetryAfterHeader) {
                                    $IsRetryable = $true
                                    # Retry-After can be seconds (integer) or HTTP date
                                    $RetryAfterValue = $null
                                    if ([int]::TryParse($RetryAfterHeader, [ref]$RetryAfterValue)) {
                                        $RetryDelay = $RetryAfterValue
                                        Write-Verbose -Message "Graph API provided Retry-After value: $($RetryDelay) seconds"
                                    }
                                    else {
                                        # Try parsing as HTTP date
                                        $RetryAfterDate = $null
                                        if ([DateTime]::TryParse($RetryAfterHeader, [ref]$RetryAfterDate)) {
                                            $RetryDelay = [Math]::Max(1, [int](($RetryAfterDate - [DateTime]::UtcNow).TotalSeconds))
                                            Write-Verbose -Message "Graph API provided Retry-After date, calculated delay: $($RetryDelay) seconds"
                                        }
                                        else {
                                            # Could not parse Retry-After header, do not retry
                                            Write-Warning -Message "Graph throttling (429) detected but Retry-After header could not be parsed: $($RetryAfterHeader)"
                                            $IsRetryable = $false
                                        }
                                    }

                                    if ($IsRetryable -and $RetryAttempt -lt $MaxRetryAttempts) {
                                        Write-Warning -Message "Graph throttling (429) detected. Retrying in $($RetryDelay) seconds (Attempt $($RetryAttempt) of $($MaxRetryAttempts))"
                                    }
                                }
                                else {
                                    # No Retry-After header provided by Graph API, cannot retry safely
                                    Write-Warning -Message "Graph throttling (429) detected but no Retry-After header provided"
                                    $IsRetryable = $false
                                }
                            }
                            "ServiceUnavailable" {
                                # 503 - Service temporarily unavailable
                                $IsRetryable = $true
                                $UseExponentialBackoff = $true
                            }
                            "GatewayTimeout" {
                                # 504 - Gateway timeout
                                $IsRetryable = $true
                                $UseExponentialBackoff = $true
                            }
                            "BadGateway" {
                                # 502 - Bad gateway
                                $IsRetryable = $true
                                $UseExponentialBackoff = $true
                            }
                            default {
                                # Non-retryable HTTP status code
                                $IsRetryable = $false
                            }
                        }

                        # Apply exponential backoff with jitter for service errors
                        if ($UseExponentialBackoff -and $IsRetryable) {
                            $BaseDelay = [Math]::Min(120, [Math]::Pow(2, $RetryAttempt))
                            $Jitter = Get-Random -Minimum $RetryDelayRange.Min -Maximum $RetryDelayRange.Max
                            $RetryDelay = $BaseDelay + $Jitter

                            if ($RetryAttempt -lt $MaxRetryAttempts) {
                                Write-Warning -Message "Graph service error ($($StatusCode)) detected. Retrying in $($RetryDelay) seconds (Attempt $($RetryAttempt) of $($MaxRetryAttempts))"
                            }
                        }
                    }

                    # If retryable and haven't exceeded max attempts, wait and retry
                    if ($IsRetryable -and $RetryAttempt -lt $MaxRetryAttempts) {
                        Start-Sleep -Seconds $RetryDelay
                        continue
                    }

                    # If not retryable or max retries exceeded, handle final error
                    if ($RetryAttempt -ge $MaxRetryAttempts) {
                        Write-Warning -Message "Graph request failed after $($MaxRetryAttempts) retry attempts"
                    }

                    # Convert status code to integer for output if available
                    $HttpStatusCodeInteger = 0
                    if ($ExceptionItem.Exception.Response.StatusCode) {
                        $HttpStatusCodeInteger = ([int][System.Net.HttpStatusCode]$ExceptionItem.Exception.Response.StatusCode)
                    }

                    # Handle error based on operation type
                    switch ($PSCmdlet.ParameterSetName) {
                        "GET" {
                            # Output warning message for GET operations
                            if ($HttpStatusCodeInteger -gt 0) {
                                Write-Warning -Message "Graph request failed with status code '$($HttpStatusCodeInteger) ($($ExceptionItem.Exception.Response.StatusCode))'. Error details: $($ResponseBody.ErrorCode) - $($ResponseBody.ErrorMessage)"
                            }
                            else {
                                Write-Warning -Message "Graph request failed. Error details: $($ResponseBody.ErrorCode) - $($ResponseBody.ErrorMessage)"
                            }

                            # Set graph response as handled and stop processing loop
                            $GraphResponseProcess = $false
                            $RequestSucceeded = $true
                        }
                        default {
                            # Throw terminating error for POST/PATCH/DELETE operations
                            $SystemException = New-Object -TypeName "System.Management.Automation.RuntimeException" -ArgumentList ("{0}: {1}" -f $ResponseBody.ErrorCode, $ResponseBody.ErrorMessage)
                            $ErrorRecord = New-Object -TypeName "System.Management.Automation.ErrorRecord" -ArgumentList @($SystemException, $ErrorID, [System.Management.Automation.ErrorCategory]::NotImplemented, [string]::Empty)

                            # Throw a terminating custom error record
                            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
                        }
                    }
                }
            }
        }
        until ($GraphResponseProcess -eq $false)

        # Handle return value
        return $GraphResponseList
    }
}
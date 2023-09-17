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
        Updated:     2021-09-08

        Version history:
        1.0.0 - (2020-10-11) Function created
        1.0.1 - (2020-11-11) Tested and verified for rate-limit and nextLink
        1.0.2 - (2021-04-12) Adjusted for usage in MSGraphRequest module
        1.0.3 - (2021-08-19) Fixed bug to handle single result
        1.0.4 - (2021-09-08) Added cross platform support for error details and fixed an error where StreamReader was used but not supported on newer PS versions.
                             Fixed bug to handle empty results when using GET operation.
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
            Write-Warning -Message "Unable to find authentication header, use Get-AccessToken function before running this function"; break
        }
    }
    Process {
        # Construct list as return value for handling both single and multiple instances in response from call
        $GraphResponseList = New-Object -TypeName "System.Collections.ArrayList"

        # Construct full URI
        $GraphURI = "https://graph.microsoft.com/$($APIVersion)/$($Resource)"
        Write-Verbose -Message "$($PSCmdlet.ParameterSetName) $($GraphURI)"        

        # Call Graph API and get JSON response
        do {
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

                # Construct response error custom object for cross platform support
                $ResponseBody = [PSCustomObject]@{
                    "ErrorMessage" = [string]::Empty
                    "ErrorCode" = [string]::Empty
                }

                # Read response error details differently depending PSVersion
                switch ($PSVersionTable.PSVersion.Major) {
                    "5" {
                        # Read the response stream
                        $StreamReader = New-Object -TypeName "System.IO.StreamReader" -ArgumentList @($ExceptionItem.Exception.Response.GetResponseStream())
                        $StreamReader.BaseStream.Position = 0
                        $StreamReader.DiscardBufferedData()
                        $ResponseReader = ($StreamReader.ReadToEnd() | ConvertFrom-Json)

                        # Set response error details
                        $ResponseBody.ErrorMessage = $ResponseReader.error.message
                        $ResponseBody.ErrorCode = $ResponseReader.error.code
                    }
                    default {
                        $ErrorDetails = $ExceptionItem.ErrorDetails.Message | ConvertFrom-Json

                        # Set response error details
                        $ResponseBody.ErrorMessage = $ErrorDetails.error.message
                        $ResponseBody.ErrorCode = $ErrorDetails.error.code
                    }
                }              

                switch ($ExceptionItem.Exception.Response.StatusCode) {
                    "TooManyRequests" {
                        # Detected throttling based from response status code
                        $RetryInSeconds = $ExceptionItem.Exception.Response.Headers["Retry-After"]

                        if ($RetryInSeconds -ne $null) {
                            # Wait for given period of time specified in response headers
                            Write-Warning -Message "Graph is throttling the request, will retry in '$($RetryInSeconds)' seconds"
                            Start-Sleep -Seconds $RetryInSeconds
                        }
                        else {
                            Write-Warning -Message "Graph is throttling the request, will retry in default '300' seconds"
                            Start-Sleep -Seconds 300
                        }
                    }
                    "GatewayTimeout" {
                        Write-Warning -Message "Graph returned Gateway Timeout for the request, will retry in default '60' seconds"
                        Start-Sleep -Seconds 60
                    }
                    default {
                        # Convert status code to integer for output
                        $HttpStatusCodeInteger = ([int][System.Net.HttpStatusCode]$ExceptionItem.Exception.Response.StatusCode)

                        switch ($PSCmdlet.ParameterSetName) {
                            "GET" {
                                # Output warning message that the request failed with error message description from response stream
                                Write-Warning -Message "Graph request failed with status code '$($HttpStatusCodeInteger) ($($ExceptionItem.Exception.Response.StatusCode))'. Error details: $($ResponseBody.ErrorCode) - $($ResponseBody.ErrorMessage)"
    
                                # Set graph response as handled and stop processing loop
                                $GraphResponseProcess = $false
                            }
                            default {
                                # Construct new custom error record
                                $SystemException = New-Object -TypeName "System.Management.Automation.RuntimeException" -ArgumentList ("{0}: {1}" -f $ResponseBody.ErrorCode, $ResponseBody.ErrorMessage)
                                $ErrorRecord = New-Object -TypeName "System.Management.Automation.ErrorRecord" -ArgumentList @($SystemException, $ErrorID, [System.Management.Automation.ErrorCategory]::NotImplemented, [string]::Empty)
    
                                # Throw a terminating custom error record
                                $PSCmdlet.ThrowTerminatingError($ErrorRecord)
                            }
                        }
    
                        # Set graph response as handled and stop processing loop
                        $GraphResponseProcess = $false
                    }
                }
            }
        }
        until ($GraphResponseProcess -eq $false)

        # Handle return value
        return $GraphResponseList
    }
}
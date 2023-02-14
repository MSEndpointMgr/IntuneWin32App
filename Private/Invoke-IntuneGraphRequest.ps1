function Invoke-IntuneGraphRequest {
    <#
    .SYNOPSIS
        Perform a specific call to Intune Graph API, either as GET, POST or PATCH methods.

    .DESCRIPTION
        Perform a specific call to Intune Graph API, either as GET, POST or PATCH methods.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-01-04
        Updated:     2023-02-03

        Version history:
        1.0.0 - (2020-01-04) Function created
        1.0.1 - (2020-04-29) Added support for DELETE operations
        1.0.2 - (2021-08-31) Updated to use new authentication header
        1.0.3 - (2022-10-02) Changed content type for requests to support UTF8
        1.0.4 - (2023-01-23) Added non-mandatory Route parameter to support different routes of Graph API in addition to better handle error response body depending on PSEdition
        1.0.5 - (2023-02-03) Improved error handling
    #>    
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Beta", "v1.0")]
        [string]$APIVersion,

        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Route = "deviceAppManagement",

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Resource,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("GET", "POST", "PATCH", "DELETE")]
        [string]$Method,

        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Object]$Body,

        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$ContentType = "application/json; charset=utf-8"
    )
    try {
        # Construct full URI
        $GraphURI = "https://graph.microsoft.com/$($APIVersion)/$($Route)/$($Resource)"
        Write-Verbose -Message "$($Method) $($GraphURI)"

        # Call Graph API and get JSON response
        switch ($Method) {
            "GET" {
                $GraphResponse = Invoke-RestMethod -Uri $GraphURI -Headers $Global:AuthenticationHeader -Method $Method -ErrorAction Stop -Verbose:$false
            }
            "POST" {
                $GraphResponse = Invoke-RestMethod -Uri $GraphURI -Headers $Global:AuthenticationHeader -Method $Method -Body $Body -ContentType $ContentType -ErrorAction Stop -Verbose:$false
            }
            "PATCH" {
                $GraphResponse = Invoke-RestMethod -Uri $GraphURI -Headers $Global:AuthenticationHeader -Method $Method -Body $Body -ContentType $ContentType -ErrorAction Stop -Verbose:$false
            }
            "DELETE" {
                $GraphResponse = Invoke-RestMethod -Uri $GraphURI -Headers $Global:AuthenticationHeader -Method $Method -ErrorAction Stop -Verbose:$false
            }
        }

        return $GraphResponse
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

        # Convert status code to integer for output
        $HttpStatusCodeInteger = ([int][System.Net.HttpStatusCode]$ExceptionItem.Exception.Response.StatusCode)

        switch ($Method) {
            "GET" {
                # Output warning message that the request failed with error message description from response stream
                Write-Warning -Message "Graph request failed with status code '$($HttpStatusCodeInteger) ($($ExceptionItem.Exception.Response.StatusCode))'. Error details: $($ResponseBody.ErrorCode) - $($ResponseBody.ErrorMessage)"
            }
            default {
                # Construct new custom error record
                $SystemException = New-Object -TypeName "System.Management.Automation.RuntimeException" -ArgumentList ("{0}: {1}" -f $ResponseBody.ErrorCode, $ResponseBody.ErrorMessage)
                $ErrorRecord = New-Object -TypeName "System.Management.Automation.ErrorRecord" -ArgumentList @($SystemException, $ErrorID, [System.Management.Automation.ErrorCategory]::NotImplemented, [string]::Empty)

                # Throw a terminating custom error record
                $PSCmdlet.ThrowTerminatingError($ErrorRecord)
            }
        }
    }
}
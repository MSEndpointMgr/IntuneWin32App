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
        Updated:     2024-12-24

        Version history:
        1.0.0 - (2020-01-04) Function created
        1.0.1 - (2020-04-29) Added support for DELETE operations
        1.0.2 - (2021-08-31) Updated to use new authentication header
        1.0.3 - (2022-10-02) Changed content type for requests to support UTF8
        1.0.4 - (2023-01-23) Added non-mandatory Route parameter to support different routes of Graph API in addition to better handle error response body depending on PSEdition
        1.0.5 - (2023-02-03) Improved error handling
        1.0.6 - (2024-12-24) Added retry logic to handle transient errors and improved error handling for pipeline use. (tjgruber)
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

    # Retry parameters
    $RetryCount = 5

    for ($i = 0; $i -lt $RetryCount; $i++) {
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

            # If successful, return the response
            return $GraphResponse

        } catch [System.Net.WebException] {
            # Capture current error
            $ExceptionItem = $PSItem

            # Check if response is a 429 TooManyRequests
            if ($ExceptionItem.Exception.Response.StatusCode -eq 429) {
                $RetryDelay = Get-Random -Minimum 7 -Maximum 13
                Write-Warning "Graph request failed with status code '429 TooManyRequests'. Retrying in [$RetryDelay] seconds... (Attempt [$($i + 1)] of [$RetryCount])"
                Start-Sleep -Seconds $RetryDelay
            } else {
                # Handle non-429 exceptions
                $ErrorMessage = "Graph request failed with status code '$($ExceptionItem.Exception.Response.StatusCode)'."
                Write-Warning $ErrorMessage

                # Extract response error details for cross-platform compatibility
                $ResponseBody = [PSCustomObject]@{
                    "ErrorMessage" = [string]::Empty
                    "ErrorCode" = [string]::Empty
                }

                switch ($PSVersionTable.PSVersion.Major) {
                    "5" {
                        # Read response stream (PowerShell 5 compatibility)
                        $StreamReader = New-Object -TypeName "System.IO.StreamReader" -ArgumentList @($ExceptionItem.Exception.Response.GetResponseStream())
                        $StreamReader.BaseStream.Position = 0
                        $StreamReader.DiscardBufferedData()
                        $ResponseReader = ($StreamReader.ReadToEnd() | ConvertFrom-Json)

                        # Set response error details
                        $ResponseBody.ErrorMessage = $ResponseReader.error.message
                        $ResponseBody.ErrorCode = $ResponseReader.error.code
                    }
                    default {
                        # Read error details for modern PowerShell versions
                        $ErrorDetails = $ExceptionItem.ErrorDetails.Message | ConvertFrom-Json
                        $ResponseBody.ErrorMessage = $ErrorDetails.error.message
                        $ResponseBody.ErrorCode = $ErrorDetails.error.code
                    }
                }

                # Check for "TransientError|Timeout|ServiceUnavailable|TooManyRequests" matches and retry
                $transientErrorMatch = "TransientError|Timeout|ServiceUnavailable|TooManyRequests"
                if ($ResponseBody.ErrorCode -match $transientErrorMatch -or $ResponseBody.ErrorMessage -match $transientErrorMatch) {
                    $RetryDelay = Get-Random -Minimum 7 -Maximum 13
                    Write-Warning "Graph request failed with transient error: $($ResponseBody.ErrorCode). Retrying in [$RetryDelay] seconds... (Attempt [$($i + 1)] of [$RetryCount])"
                    Start-Sleep -Seconds $RetryDelay
                } else {
                    # Log error details and rethrow the exception
                    Write-Warning "Error details: $($ResponseBody.ErrorCode) - $($ResponseBody.ErrorMessage)"
                    throw $ExceptionItem
                }

            }
        } catch {
            # Handle "TransientError|Timeout|ServiceUnavailable|TooManyRequests" exceptions and retry
            $transientErrorMatch = "TransientError|Timeout|ServiceUnavailable|TooManyRequests"
            if ($_.Exception.Message -match $transientErrorMatch -or $_.ErrorDetails.Message -match $transientErrorMatch) {
                $RetryDelay = Get-Random -Minimum 7 -Maximum 13
                Write-Warning "Graph request failed with transient error: $_. Retrying in [$RetryDelay] seconds... (Attempt [$($i + 1)] of [$RetryCount])"
                Start-Sleep -Seconds $RetryDelay
            }

            # Handle non-transient errors
            Write-Warning "Graph request failed with unexpected error: $_. Aborting."
            break
        }
    }

    # If all retries fail, throw an error
    throw "Graph request failed after $RetryCount attempts. Aborting."
}

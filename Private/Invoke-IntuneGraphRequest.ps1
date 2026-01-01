function Invoke-IntuneGraphRequest {
    <#
    .SYNOPSIS
        Perform a specific call to Intune Graph API, either as GET, POST, PATCH, or DELETE.

    .DESCRIPTION
        Perform a specific call to Intune Graph API with retry logic for transient errors.

    .PARAMETER APIVersion
        The Graph API version (e.g., Beta, v1.0).

    .PARAMETER Route
        The API route (default: "deviceAppManagement").

    .PARAMETER Resource
        The resource path for the API call.

    .PARAMETER Method
        The HTTP method to use (GET, POST, PATCH, DELETE).

    .PARAMETER Body
        The body of the request (for POST or PATCH).

    .PARAMETER ContentType
        The content type of the request (default: "application/json; charset=utf-8").

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
        1.0.6 - (2025-01-14) Rewritten to handle transient errors and improved error handling for pipeline use. (tjgruber)
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
    $RetryCount = 8
    $RetryDelayRange = @{ Min = 7; Max = 30 }
    $TransientErrors = "TransientError|Timeout|ServiceUnavailable|TooManyRequests|429|503"

    for ($Attempt = 1; $Attempt -le $RetryCount; $Attempt++) {
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
            # Handle WebException for transient errors
            $StatusCode = $_.Exception.Response.StatusCode
            if ($StatusCode -eq 429 -or $StatusCode -eq 503) {
                $RetryDelay = Get-Random -Minimum $RetryDelayRange.Min -Maximum $RetryDelayRange.Max
                Write-Warning "Request failed with status code [$StatusCode]. Retrying in [$RetryDelay] seconds... (Attempt [$Attempt] of [$RetryCount])"
                Start-Sleep -Seconds $RetryDelay
                continue
            }

            # Handle non-retryable WebException
            Write-Warning "Non-retryable WebException occurred. Status code: [$StatusCode]. Message: [$($_.Exception.Message)]"
            throw $_
        } catch {
            # Handle other exceptions (e.g., transient error patterns)
            if ($_.Exception.Message -match $TransientErrors) {
                $RetryDelay = Get-Random -Minimum $RetryDelayRange.Min -Maximum $RetryDelayRange.Max
                Write-Warning "Transient error detected. Retrying in [$RetryDelay] seconds... (Attempt [$Attempt] of [$RetryCount])"
                Start-Sleep -Seconds $RetryDelay
                continue
            }

            # Handle non-retryable errors
            Write-Warning "Non-retryable error occurred. Message: [$($_.Exception.Message)]"
            throw $_
        }
    }

    # All retries failed
    throw "Graph request failed after [$RetryCount] attempts. Aborting."
}

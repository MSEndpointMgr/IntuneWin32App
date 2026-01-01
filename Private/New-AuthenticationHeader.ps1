function New-AuthenticationHeader {
    <#
    .SYNOPSIS
        Construct a required header hash-table based on the access token from Get-AccessToken function.

    .DESCRIPTION
        Construct a required header hash-table based on the access token from Get-AccessToken function.

    .PARAMETER AccessToken
        Pass the AuthenticationResult object returned from Get-AccessToken cmdlet.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2021-04-08
        Updated:     2021-09-08

        Version history:
        1.0.0 - (2021-04-08) Script created
        1.0.1 - (2021-09-08) Fixed issue reported by Paul DeArment Jr where the local date time set for ExpiresOn should be UTC to not cause any time related issues
        1.0.2 - (2024-05-29) Updated to support access tokens from New-ClientCredentialsAccessToken function (thanks to @tjgruber)
    #>
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Pass the AuthenticationResult object returned from Get-AccessToken cmdlet.")]
        [ValidateNotNullOrEmpty()]
        $AccessToken
    )
    Process {
        # Construct default header parameters
        $AuthenticationHeader = @{
            "Content-Type"  = "application/json"
            "Authorization" = "Bearer $($AccessToken.access_token)"
        }

        # Check if ExpiresOn property is available
        if ($AccessToken.PSObject.Properties["ExpiresOn"]) {
            $AuthenticationHeader["ExpiresOn"] = $AccessToken.ExpiresOn.ToUniversalTime()
        }
        else {
            Write-Warning "The access token does not contain an ExpiresOn property. The ExpiresOn field in the authentication header will not be set."
        }

        # Handle return value
        return $AuthenticationHeader
    }
}

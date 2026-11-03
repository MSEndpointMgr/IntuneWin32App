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
        1.0.3 - (2026-11-03) Removed ExpiresOn from the header table, since it was sent as an HTTP request header and fails on non en-US date formats
                             and on macOS where header values must be ASCII (#182). Use Test-AccessToken to check token expiration.
    #>
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Pass the AuthenticationResult object returned from Get-AccessToken cmdlet.")]
        [ValidateNotNullOrEmpty()]
        $AccessToken
    )
    Process {
        # Construct default header parameters, only valid HTTP request headers are added since this table is passed as headers to every request
        $AuthenticationHeader = @{
            "Content-Type"  = "application/json"
            "Authorization" = "Bearer $($AccessToken.access_token)"
        }

        # Handle return value
        return $AuthenticationHeader
    }
}

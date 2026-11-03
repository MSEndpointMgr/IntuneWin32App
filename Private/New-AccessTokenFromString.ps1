function New-AccessTokenFromString {
    <#
    .SYNOPSIS
        Construct the global access token object from an existing access token string.

    .DESCRIPTION
        Construct the global access token object from an existing access token string, e.g. retrieved with Get-AzAccessToken,
        Get-MgContext workflows, az account get-access-token or a pipeline task. The expiration time is read from the 'exp' claim of the token.

    .PARAMETER AccessToken
        Specify the access token for Microsoft Graph, as a plain string or SecureString.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2026-11-03
        Updated:     2026-11-03

        Version history:
        1.0.0 - (2026-11-03) Function created (#114, #152)
    #>
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the access token for Microsoft Graph, as a plain string or SecureString.")]
        [ValidateNotNullOrEmpty()]
        [System.Object]$AccessToken
    )
    Process {
        if ($AccessToken -is [System.Security.SecureString]) {
            $AccessToken = [System.Net.NetworkCredential]::new([string]::Empty, $AccessToken).Password
        }
        $AccessToken = ([string]$AccessToken).Trim()
        if ($AccessToken -like "Bearer *") {
            $AccessToken = $AccessToken.Substring(7).Trim()
        }

        # Decode the JWT payload to determine the expiration time
        $Claims = Get-AccessTokenClaims -AccessToken $AccessToken
        if ($null -eq $Claims.exp) {
            throw "The provided access token does not contain an expiration claim"
        }

        $Scopes = if ($Claims.scp) { $Claims.scp -split " " } elseif ($Claims.roles) { @($Claims.roles) } else { @("https://graph.microsoft.com/.default") }
        $TokenObject = [PSCustomObject]@{
            "access_token" = $AccessToken
            "token_type" = "Bearer"
            "AccessToken" = $AccessToken
            "ExpiresOn" = [DateTimeOffset]::FromUnixTimeSeconds([int64]$Claims.exp).UtcDateTime
            "Scopes" = $Scopes
        }

        # Set global variable
        $Global:AccessToken = $TokenObject
        return $Claims
    }
}

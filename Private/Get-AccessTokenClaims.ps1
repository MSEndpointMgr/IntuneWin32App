function Get-AccessTokenClaims {
    <#
    .SYNOPSIS
        Decode the claims of a JSON Web Token access token.

    .DESCRIPTION
        Decode the claims of a JSON Web Token access token. The signature is not validated, the claims are only used to read
        properties such as the tenant ID and expiration time of a token that was issued to this session.

    .PARAMETER AccessToken
        Specify the access token as a string.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2026-11-03
        Updated:     2026-11-03

        Version history:
        1.0.0 - (2026-11-03) Function created
    #>
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the access token as a string.")]
        [ValidateNotNullOrEmpty()]
        [string]$AccessToken
    )
    Process {
        $TokenParts = $AccessToken.Split(".")
        if ($TokenParts.Count -lt 2) {
            throw "The provided access token is not a valid JSON Web Token"
        }
        $Payload = $TokenParts[1].Replace("-", "+").Replace("_", "/")
        switch ($Payload.Length % 4) {
            2 { $Payload += "==" }
            3 { $Payload += "=" }
        }
        try {
            return ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Payload)) | ConvertFrom-Json -ErrorAction Stop)
        }
        catch {
            throw "Unable to decode the provided access token: $($_)"
        }
    }
}

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
        Updated:     2021-04-08

        Version history:
        1.0.0 - (2021-04-08) Script created
    #>
    param(
        [parameter(Mandatory = $true, HelpMessage = "Pass the AuthenticationResult object returned from Get-AccessToken cmdlet.")]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Identity.Client.AuthenticationResult]$AccessToken
    )
    Process {
        # Construct default header parameters
        $AuthenticationHeader = @{
            "Content-Type" = "application/json"
            "Authorization" = $AccessToken.CreateAuthorizationHeader()
            "ExpiresOn" = $AccessToken.ExpiresOn.LocalDateTime
        }

        # Handle return value
        return $AuthenticationHeader
    }
}
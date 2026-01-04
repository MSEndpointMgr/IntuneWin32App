function New-ClientCredentialsAccessToken {
    <#
    .SYNOPSIS
        Requests an access token using the client credentials flow.

    .DESCRIPTION
        Requests an access token using the client credentials flow.

    .PARAMETER TenantID
        Tenant ID of the Azure AD tenant.

    .PARAMETER ClientID
        Application ID (Client ID) for an Azure AD service principal.

    .PARAMETER ClientSecret
        Application secret (Client Secret) for an Azure AD service principal.

    .NOTES
        Author:      Timothy Gruber
        Contact:     @tjgruber
        Created:     2024-05-29
        Updated:     2024-05-29

        Version history:
        1.0.0 - (2024-05-29) Script created
    #>
    param(
        [parameter(Mandatory = $true, HelpMessage = "Tenant ID of the Azure AD tenant.")]
        [ValidateNotNullOrEmpty()]
        [String]$TenantID,

        [parameter(Mandatory = $true, HelpMessage = "Application ID (Client ID) for an Azure AD service principal.")]
        [ValidateNotNullOrEmpty()]
        [String]$ClientID,

        [parameter(Mandatory = $true, HelpMessage = "Application secret (Client Secret) for an Azure AD service principal.")]
        [ValidateNotNullOrEmpty()]
        [String]$ClientSecret
    )
    Process {
        $graphRequestUri = "https://login.microsoftonline.com/$($TenantID)/oauth2/v2.0/token"
        $graphTokenRequestBody = @{
            "client_id" = $ClientID
            "scope" = "https://graph.microsoft.com/.default"
            "client_secret" = $ClientSecret
            "grant_type" = "client_credentials"
        }

        try {
            $GraphAPIAuthResult = Invoke-RestMethod -Method Post -Uri $graphRequestUri -Body $graphTokenRequestBody -ErrorAction Stop

            # Validate the result
            if (-not $GraphAPIAuthResult.access_token) {
                throw "No access token was returned in the response."
            }

            # Calculate the ExpiresOn property based on the expires_in value
            $GraphAPIAuthResult | Add-Member -MemberType NoteProperty -Name "ExpiresOn" -Value ((Get-Date).AddSeconds($GraphAPIAuthResult.expires_in).ToUniversalTime()) -Force
            
            # Add Scopes property for permission tracking
            $GraphAPIAuthResult | Add-Member -MemberType NoteProperty -Name "Scopes" -Value @("https://graph.microsoft.com/.default") -Force
            
            # Add AccessToken property for consistent access
            $GraphAPIAuthResult | Add-Member -MemberType NoteProperty -Name "AccessToken" -Value $GraphAPIAuthResult.access_token -Force

            # Set global variable
            $Global:AccessToken = $GraphAPIAuthResult
        }
        catch {
            throw "Error retrieving the access token: $($_)"
        }
    }
}

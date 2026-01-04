function Update-AccessTokenFromRefreshToken {
    <#
    .SYNOPSIS
        Silently refreshes an access token using a refresh token.

    .DESCRIPTION
        Silently refreshes an access token using a refresh token obtained from a previous authentication.
        This function allows for unattended token renewal without requiring user interaction.

    .PARAMETER TenantID
        Tenant ID of the Entra ID tenant.

    .PARAMETER ClientID
        Application ID (Client ID) for an Entra ID service principal.

    .PARAMETER RefreshToken
        The refresh token obtained from a previous authentication response.

    .PARAMETER Scopes
        Array of permission scopes to request. Defaults to the original scopes used during authentication.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2026-01-04
        Updated:     2026-01-04

        Version history:
        1.0.0 - (2026-01-04) Function created
    #>
    param(
        [parameter(Mandatory = $true, HelpMessage = "Tenant ID of the Entra ID tenant.")]
        [ValidateNotNullOrEmpty()]
        [String]$TenantID,

        [parameter(Mandatory = $true, HelpMessage = "Application ID (Client ID) for an Entra ID service principal.")]
        [ValidateNotNullOrEmpty()]
        [String]$ClientID,

        [parameter(Mandatory = $true, HelpMessage = "The refresh token obtained from a previous authentication response.")]
        [ValidateNotNullOrEmpty()]
        [String]$RefreshToken,

        [parameter(Mandatory = $false, HelpMessage = "Array of permission scopes to request.")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Scopes = @("DeviceManagementApps.ReadWrite.All", "DeviceManagementRBAC.Read.All")
    )
    Process {
        try {
            Write-Verbose -Message "Attempting to refresh access token using refresh token"

            # Build token refresh request
            $TokenUri = "https://login.microsoftonline.com/$($TenantID)/oauth2/v2.0/token"
            $ScopeString = $Scopes -join " "
            
            $TokenBody = @{
                "client_id" = $ClientID
                "scope" = $ScopeString
                "refresh_token" = $RefreshToken
                "grant_type" = "refresh_token"
            }

            # Request new access token using refresh token
            $TokenResponse = Invoke-RestMethod -Method Post -Uri $TokenUri -Body $TokenBody -ErrorAction Stop

            # Validate the result
            if (-not $TokenResponse.access_token) {
                throw "No access token was returned in the response"
            }

            Write-Verbose -Message "Successfully refreshed access token"

            # Add ExpiresOn property for token expiration tracking
            $TokenResponse | Add-Member -MemberType NoteProperty -Name "ExpiresOn" -Value ((Get-Date).AddSeconds($TokenResponse.expires_in).ToUniversalTime()) -Force
            
            # Add Scopes property for permission tracking
            $TokenResponse | Add-Member -MemberType NoteProperty -Name "Scopes" -Value ($TokenResponse.scope -split " ") -Force
            
            # Add AccessToken property for consistent access
            $TokenResponse | Add-Member -MemberType NoteProperty -Name "AccessToken" -Value $TokenResponse.access_token -Force

            # Update global variable
            $Global:AccessToken = $TokenResponse
        }
        catch {
            throw "Error refreshing access token: $($_)"
        }
    }
}

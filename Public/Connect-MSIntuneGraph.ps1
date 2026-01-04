function Connect-MSIntuneGraph {
    <#
    .SYNOPSIS
        Get or refresh an access token using various authentication flows for the Graph API.

    .DESCRIPTION
        Get or refresh an access token using either authorization code flow or client credentials flow, that can be used to authenticate and authorize against resources in Graph API.

    .PARAMETER TenantID
        Specify the tenant name or ID, e.g. tenant.onmicrosoft.com or <GUID>.

    .PARAMETER ClientID
        Application ID (Client ID) for an Azure AD service principal.

    .PARAMETER ClientSecret
        Application secret (Client Secret) for an Azure AD service principal.

    .PARAMETER ClientCert
        A Certificate object (not just thumbprint) representing the client certificate for an Azure AD service principal.

    .PARAMETER RedirectUri
        Specify the Redirect URI (also known as Reply URL) of the custom Azure AD service principal.

    .PARAMETER Interactive
        Specify to force an interactive prompt for credentials using OAuth 2.0 Authorization Code flow with PKCE.

    .PARAMETER DeviceCode
        Specify to use device code authentication flow for environments where interactive browser is not available.

    .PARAMETER Refresh
        Specify to refresh an existing access token. Note: Token refresh is not currently implemented.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2021-08-31
        Updated:     2026-01-04

        Version history:
        1.0.0 - (2021-08-31) Script created
        1.0.1 - (2022-03-28) Added ClientSecret parameter input to support client secret auth flow
        1.0.2 - (2022-09-03) Added new global variable to hold the tenant id passed as parameter input for access token refresh scenario
        1.0.3 - (2023-04-07) Added support for client certificate auth flow (thanks to apcsb)
        1.0.4 - (2024-05-29) Updated to integrate New-ClientCredentialsAccessToken function for client secret flow (thanks to @tjgruber)
        1.0.5 - (2025-12-07) BREAKING CHANGE: Removed deprecated Microsoft Intune PowerShell enterprise application fallback, ClientID now mandatory
        1.0.6 - (2026-01-02) BREAKING CHANGE: Removed MSAL.PS dependency, now uses New-DelegatedAccessToken for Interactive and New-ClientCredentialsAccessToken for ClientSecret flows
        1.0.7 - (2026-01-02) Added DeviceCode authentication flow support using New-DeviceCodeAccessToken
        1.0.8 - (2026-01-04) Implemented silent token refresh using Update-AccessTokenFromRefreshToken function
    #>
    [CmdletBinding(DefaultParameterSetName = "Interactive")]
    param(
        [parameter(Mandatory = $true, ParameterSetName = "Interactive", HelpMessage = "Specify the tenant name or ID, e.g. tenant.onmicrosoft.com or <GUID>.")]
        [parameter(Mandatory = $true, ParameterSetName = "DeviceCode")]
        [parameter(Mandatory = $true, ParameterSetName = "ClientSecret")]
        [parameter(Mandatory = $true, ParameterSetName = "ClientCert")]
        [ValidateNotNullOrEmpty()]
        [string]$TenantID,
        
        [parameter(Mandatory = $true, ParameterSetName = "Interactive", HelpMessage = "Application ID (Client ID) for an Entra ID service principal.")]
        [parameter(Mandatory = $true, ParameterSetName = "DeviceCode")]
        [parameter(Mandatory = $true, ParameterSetName = "ClientSecret")]
        [parameter(Mandatory = $true, ParameterSetName = "ClientCert")]
        [ValidateNotNullOrEmpty()]
        [string]$ClientID,

        [parameter(Mandatory = $false, HelpMessage = "Application secret (Client Secret) for an Entra ID service principal.")]
        [parameter(Mandatory = $true, ParameterSetName = "ClientSecret")]
        [ValidateNotNullOrEmpty()]
        [string]$ClientSecret,

        [parameter(Mandatory = $false, HelpMessage = "A Certificate object (not just thumbprint) representing the client certificate for an Azure AD service principal.")]
        [parameter(Mandatory = $true, ParameterSetName = "ClientCert")]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$ClientCert,

        [parameter(Mandatory = $false, ParameterSetName = "Interactive", HelpMessage = "Specify the Redirect URI (also known as Reply URL) of the custom Azure AD service principal.")]
        [ValidateNotNullOrEmpty()]
        [string]$RedirectUri = [string]::Empty,

        [parameter(Mandatory = $false, ParameterSetName = "Interactive", HelpMessage = "Specify to force an interactive prompt for credentials.")]
        [switch]$Interactive,

        [parameter(Mandatory = $false, ParameterSetName = "DeviceCode", HelpMessage = "Specify to use device code authentication flow.")]
        [switch]$DeviceCode,

        [parameter(Mandatory = $false, ParameterSetName = "Interactive", HelpMessage = "Specify to refresh an existing access token using stored refresh token.")]
        [parameter(Mandatory = $false, ParameterSetName = "DeviceCode")]
        [switch]$Refresh
    )
    Begin {
        # Determine the correct RedirectUri (also known as Reply URL) for OAuth authentication
        Write-Verbose -Message "Using Entra ID service principal with Application ID: $($ClientID)"

        # Adjust RedirectUri parameter input in case none was passed on command line
        if ([string]::IsNullOrEmpty($RedirectUri)) {
            # Use http://localhost for loopback redirect (dynamic port will be assigned)
            $RedirectUri = "http://localhost"
        }

        Write-Verbose -Message "Using RedirectUri with value: $($RedirectUri)"

        # Set default error action preference configuration
        $ErrorActionPreference = "Stop"
    }
    Process {
        Write-Verbose -Message "Using authentication flow: $($PSCmdlet.ParameterSetName)"

        try {
            # Handle token refresh if requested and refresh token is available
            if ($PSBoundParameters.ContainsKey("Refresh") -and $Refresh) {
                if ($null -ne $Global:AccessToken -and $Global:AccessToken.PSObject.Properties["RefreshToken"] -and -not [string]::IsNullOrEmpty($Global:AccessToken.RefreshToken)) {
                    Write-Verbose -Message "Refresh parameter specified and refresh token available, attempting silent token refresh"
                    try {
                        $Scopes = if ($Global:AccessToken.PSObject.Properties["Scopes"]) { $Global:AccessToken.Scopes } else { @("DeviceManagementApps.ReadWrite.All", "DeviceManagementRBAC.Read.All") }
                        Update-AccessTokenFromRefreshToken -TenantID $TenantID -ClientID $ClientID -RefreshToken $Global:AccessToken.RefreshToken -Scopes $Scopes
                        Write-Verbose -Message "Successfully refreshed access token silently"
                        
                        # Construct the required authentication header
                        $Global:AuthenticationHeader = New-AuthenticationHeader -AccessToken $Global:AccessToken
                        Write-Verbose -Message "Successfully constructed authentication header"
                        
                        return $Global:AuthenticationHeader
                    }
                    catch {
                        Write-Warning -Message "Silent token refresh failed: $($_). Falling back to interactive authentication"
                    }
                }
                else {
                    Write-Verbose -Message "Refresh parameter specified but no refresh token available, proceeding with standard authentication"
                }
            }
            
            # Handle different authentication flows
            switch ($PSCmdlet.ParameterSetName) {
                "Interactive" {
                    Write-Verbose -Message "Using New-DelegatedAccessToken for interactive authentication"
                    try {
                        New-DelegatedAccessToken -TenantID $TenantID -ClientID $ClientID -RedirectUri $RedirectUri
                        $Global:AccessTokenTenantID = $TenantID
                        Write-Verbose -Message "Successfully retrieved access token using New-DelegatedAccessToken"
                    }
                    catch {
                        Write-Error -Message "An error occurred while retrieving access token using interactive authentication: $($_)"
                        return
                    }
                }
                "DeviceCode" {
                    Write-Verbose -Message "Using New-DeviceCodeAccessToken for device code authentication"
                    try {
                        New-DeviceCodeAccessToken -TenantID $TenantID -ClientID $ClientID
                        $Global:AccessTokenTenantID = $TenantID
                        Write-Verbose -Message "Successfully retrieved access token using New-DeviceCodeAccessToken"
                    }
                    catch {
                        Write-Error -Message "An error occurred while retrieving access token using device code authentication: $($_)"
                        return
                    }
                }
                "ClientSecret" {
                    Write-Verbose -Message "Using New-ClientCredentialsAccessToken for client secret authentication"
                    try {
                        New-ClientCredentialsAccessToken -TenantID $TenantID -ClientID $ClientID -ClientSecret $ClientSecret
                        $Global:AccessTokenTenantID = $TenantID
                        Write-Verbose -Message "Successfully retrieved access token using client credentials"
                    }
                    catch {
                        Write-Error -Message "An error occurred while retrieving access token using client credentials: $($_)"
                        return
                    }
                }
                "ClientCert" {
                    Write-Error -Message "ClientCert authentication flow is not yet implemented without MSAL.PS. Use -ClientSecret parameter instead."
                    return
                }
            }

            try {
                # Validate that access token was successfully retrieved
                if (($null -eq $Global:AccessToken) -or ([string]::IsNullOrEmpty($Global:AccessToken.AccessToken))) {
                    Write-Error -Message "Failed to retrieve access token"
                    return
                }
                
                # Construct the required authentication header
                $Global:AuthenticationHeader = New-AuthenticationHeader -AccessToken $Global:AccessToken
                Write-Verbose -Message "Successfully constructed authentication header"

                # Handle return value
                return $Global:AuthenticationHeader
            }
            catch {
                Write-Warning -Message "An error occurred while attempting to construct authentication header: $($_)"
            }
        }
        catch {
            Write-Warning -Message "An error occurred while constructing parameter input for access token retrieval: $($_)"
        }
    }
}

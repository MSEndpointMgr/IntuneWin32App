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
        The certificate must contain the private key and be valid (not expired).

    .PARAMETER RedirectUri
        Specify the Redirect URI (also known as Reply URL) of the custom Azure AD service principal.

    .PARAMETER Interactive
        Specify to force an interactive prompt for credentials using OAuth 2.0 Authorization Code flow with PKCE.

    .PARAMETER DeviceCode
        Specify to use device code authentication flow for environments where interactive browser is not available.

    .PARAMETER Refresh
        Specify to refresh an existing access token using stored refresh token.

    .PARAMETER Scopes
        Specify the permission scopes to request. Defaults include DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementRBAC.Read.All, Group.Read.All, and offline_access for full module functionality.

    .PARAMETER ManagedIdentity
        Specify to authenticate using an Azure managed identity, e.g. from Azure Automation, Azure Functions, Azure App Service, Azure Arc or an Azure Virtual Machine.

    .PARAMETER ManagedIdentityClientID
        Specify the Client ID of a user-assigned managed identity. When not specified, the system-assigned managed identity is used.

    .PARAMETER AccessToken
        Specify an existing access token for Microsoft Graph, as a plain string or SecureString, e.g. from Get-AzAccessToken or a pipeline task.
        The token cannot be renewed silently, call Connect-MSIntuneGraph again with a new token when it expires.

    .PARAMETER PassThru
        Specify to return the authentication header, which contains the bearer token, to the pipeline.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2021-08-31
        Updated:     2026-11-03

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
        1.0.9 - (2026-01-18) Implemented native client certificate authentication using New-ClientCertificateAccessToken function - completes all OAuth 2.0 flows without external dependencies
        1.1.0 - (2026-01-18) Fixed Issue #208: Ensured offline_access scope is included in token refresh requests to maintain refresh token continuity
        1.1.1 - (2026-01-18) Added Scopes parameter to allow users to customize requested permissions while providing sensible defaults for full module functionality
        1.1.2 - (2026-11-03) BREAKING CHANGE: The authentication header (including the bearer token) is no longer written to the pipeline unless PassThru is specified (#229).
                             Authentication failures now raise a terminating error instead of a warning (#228). Refresh parameter is now supported for all flows,
                             ClientSecret and ClientCert flows request a new token (#75, #130). Added ManagedIdentity (#201) and AccessToken (#114) parameter sets.
    #>
    [CmdletBinding(DefaultParameterSetName = "Interactive")]
    param(
        [parameter(Mandatory = $true, ParameterSetName = "Interactive", HelpMessage = "Specify the tenant name or ID, e.g. tenant.onmicrosoft.com or <GUID>.")]
        [parameter(Mandatory = $true, ParameterSetName = "DeviceCode")]
        [parameter(Mandatory = $true, ParameterSetName = "ClientSecret")]
        [parameter(Mandatory = $true, ParameterSetName = "ClientCert")]
        [parameter(Mandatory = $false, ParameterSetName = "ManagedIdentity")]
        [parameter(Mandatory = $false, ParameterSetName = "AccessToken")]
        [ValidateNotNullOrEmpty()]
        [string]$TenantID,

        [parameter(Mandatory = $true, ParameterSetName = "Interactive", HelpMessage = "Application ID (Client ID) for an Entra ID service principal.")]
        [parameter(Mandatory = $true, ParameterSetName = "DeviceCode")]
        [parameter(Mandatory = $true, ParameterSetName = "ClientSecret")]
        [parameter(Mandatory = $true, ParameterSetName = "ClientCert")]
        [ValidateNotNullOrEmpty()]
        [string]$ClientID,

        [parameter(Mandatory = $true, ParameterSetName = "ClientSecret", HelpMessage = "Application secret (Client Secret) for an Entra ID service principal.")]
        [ValidateNotNullOrEmpty()]
        [string]$ClientSecret,

        [parameter(Mandatory = $true, ParameterSetName = "ClientCert", HelpMessage = "A Certificate object (not just thumbprint) representing the client certificate for an Azure AD service principal.")]
        [ValidateNotNullOrEmpty()]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$ClientCert,

        [parameter(Mandatory = $false, ParameterSetName = "Interactive", HelpMessage = "Specify the Redirect URI (also known as Reply URL) of the custom Azure AD service principal.")]
        [ValidateNotNullOrEmpty()]
        [string]$RedirectUri = [string]::Empty,

        [parameter(Mandatory = $false, ParameterSetName = "Interactive", HelpMessage = "Specify to force an interactive prompt for credentials.")]
        [switch]$Interactive,

        [parameter(Mandatory = $true, ParameterSetName = "DeviceCode", HelpMessage = "Specify to use device code authentication flow.")]
        [switch]$DeviceCode,

        [parameter(Mandatory = $true, ParameterSetName = "ManagedIdentity", HelpMessage = "Specify to authenticate using an Azure managed identity.")]
        [switch]$ManagedIdentity,

        [parameter(Mandatory = $false, ParameterSetName = "ManagedIdentity", HelpMessage = "Specify the Client ID of a user-assigned managed identity.")]
        [ValidateNotNullOrEmpty()]
        [string]$ManagedIdentityClientID = [string]::Empty,

        [parameter(Mandatory = $true, ParameterSetName = "AccessToken", HelpMessage = "Specify an existing access token for Microsoft Graph.")]
        [ValidateNotNullOrEmpty()]
        [System.Object]$AccessToken,

        [parameter(Mandatory = $false, ParameterSetName = "Interactive", HelpMessage = "Specify to refresh an existing access token using stored refresh token.")]
        [parameter(Mandatory = $false, ParameterSetName = "DeviceCode")]
        [parameter(Mandatory = $false, ParameterSetName = "ClientSecret")]
        [parameter(Mandatory = $false, ParameterSetName = "ClientCert")]
        [parameter(Mandatory = $false, ParameterSetName = "ManagedIdentity")]
        [switch]$Refresh,

        [parameter(Mandatory = $false, HelpMessage = "Array of permission scopes to request.")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Scopes = @("DeviceManagementApps.ReadWrite.All", "DeviceManagementConfiguration.ReadWrite.All", "DeviceManagementRBAC.Read.All", "Group.Read.All", "offline_access"),

        [parameter(Mandatory = $false, HelpMessage = "Specify to return the authentication header, which contains the bearer token, to the pipeline.")]
        [switch]$PassThru
    )
    Begin {
        if ($PSCmdlet.ParameterSetName -in @("Interactive", "DeviceCode", "ClientSecret", "ClientCert")) {
            Write-Verbose -Message "Using Entra ID service principal with Application ID: $($ClientID)"
        }

        # Adjust RedirectUri parameter input in case none was passed on command line
        if ([string]::IsNullOrEmpty($RedirectUri)) {
            # Use http://localhost for loopback redirect (dynamic port will be assigned)
            $RedirectUri = "http://localhost"
        }
        if ($PSCmdlet.ParameterSetName -eq "Interactive") {
            Write-Verbose -Message "Using RedirectUri with value: $($RedirectUri)"
        }
    }
    Process {
        Write-Verbose -Message "Using authentication flow: $($PSCmdlet.ParameterSetName)"

        # Handle token refresh if requested and the existing connection uses the same flow, tenant and client
        $RefreshCompleted = $false
        if ($Refresh) {
            $Connection = $Script:IntuneGraphConnection
            $IsSameConnection = ($null -ne $Connection) -and ($Connection.Flow -eq $PSCmdlet.ParameterSetName) -and ([string]::IsNullOrEmpty($TenantID) -or ($Connection.TenantID -eq $TenantID)) -and ([string]::IsNullOrEmpty($ClientID) -or ($Connection.ClientID -eq $ClientID))
            if ($IsSameConnection) {
                try {
                    Update-AccessTokenIfRequired -Force
                    $RefreshCompleted = $true
                    Write-Verbose -Message "Successfully refreshed access token silently"
                }
                catch {
                    Write-Warning -Message "Silent token refresh failed: $($_). Falling back to standard authentication"
                }
            }
            else {
                Write-Verbose -Message "Refresh parameter specified but no matching connection is available, proceeding with standard authentication"
            }
        }

        if (-not($RefreshCompleted)) {
            try {
                switch ($PSCmdlet.ParameterSetName) {
                    "Interactive" {
                        Write-Verbose -Message "Using New-DelegatedAccessToken for interactive authentication"
                        $null = New-DelegatedAccessToken -TenantID $TenantID -ClientID $ClientID -RedirectUri $RedirectUri -Scopes $Scopes
                    }
                    "DeviceCode" {
                        Write-Verbose -Message "Using New-DeviceCodeAccessToken for device code authentication"
                        $null = New-DeviceCodeAccessToken -TenantID $TenantID -ClientID $ClientID -Scopes $Scopes
                    }
                    "ClientSecret" {
                        Write-Verbose -Message "Using New-ClientCredentialsAccessToken for client secret authentication"
                        $null = New-ClientCredentialsAccessToken -TenantID $TenantID -ClientID $ClientID -ClientSecret $ClientSecret
                    }
                    "ClientCert" {
                        Write-Verbose -Message "Using New-ClientCertificateAccessToken for client certificate authentication"
                        $null = New-ClientCertificateAccessToken -TenantID $TenantID -ClientID $ClientID -ClientCertificate $ClientCert
                    }
                    "ManagedIdentity" {
                        Write-Verbose -Message "Using New-ManagedIdentityAccessToken for managed identity authentication"
                        $null = New-ManagedIdentityAccessToken -ClientID $ManagedIdentityClientID
                        if ([string]::IsNullOrEmpty($TenantID)) {
                            $TenantID = (Get-AccessTokenClaims -AccessToken $Global:AccessToken.access_token).tid
                        }
                    }
                    "AccessToken" {
                        Write-Verbose -Message "Using provided access token"
                        $TokenClaims = New-AccessTokenFromString -AccessToken $AccessToken
                        if ([string]::IsNullOrEmpty($TenantID) -and $TokenClaims.tid) {
                            $TenantID = $TokenClaims.tid
                        }
                    }
                }
                if (($null -eq $Global:AccessToken) -or ([string]::IsNullOrEmpty($Global:AccessToken.AccessToken))) {
                    throw "No access token was returned"
                }
            }
            catch {
                $ErrorRecord = New-Object -TypeName "System.Management.Automation.ErrorRecord" -ArgumentList @(
                    (New-Object -TypeName "System.Exception" -ArgumentList "An error occurred while retrieving access token using authentication flow '$($PSCmdlet.ParameterSetName)': $($_)"),
                    "AccessTokenRetrievalFailed",
                    [System.Management.Automation.ErrorCategory]::AuthenticationError,
                    $TenantID
                )
                $PSCmdlet.ThrowTerminatingError($ErrorRecord)
            }
            Write-Verbose -Message "Successfully retrieved access token"

            # Store connection details in module scope for silent token renewal
            $Global:AccessTokenTenantID = $TenantID
            $Global:AccessTokenClientID = $ClientID
            $Script:IntuneGraphConnection = @{
                "Flow" = $PSCmdlet.ParameterSetName
                "TenantID" = $TenantID
                "ClientID" = $ClientID
                "ClientSecret" = $ClientSecret
                "ClientCert" = $ClientCert
                "ManagedIdentityClientID" = $ManagedIdentityClientID
            }

            # Construct the required authentication header
            $Global:AuthenticationHeader = New-AuthenticationHeader -AccessToken $Global:AccessToken
            Write-Verbose -Message "Successfully constructed authentication header"
        }

        # Handle return value, the authentication header contains the bearer token and is only returned when requested
        if ($PassThru) {
            return $Global:AuthenticationHeader
        }
    }
}

function Connect-MSIntuneGraph {
    <#
    .SYNOPSIS
        Get or refresh an access token using various authentication flows for the Graph API.

    .DESCRIPTION
        Get or refresh an access token using either authorization code flow or device code flow, that can be used to authenticate and authorize against resources in Graph API.
        
        Note: When running in Windows Terminal, use the -DeviceCode parameter to avoid "Error creating window handle" issues with interactive authentication.

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

    .PARAMETER DeviceCode
        Specify delegated login using devicecode flow, you will be prompted to navigate to https://microsoft.com/devicelogin
        This method is recommended when running in Windows Terminal or other environments where window handle creation may fail.

    .PARAMETER Interactive
        Specify to force an interactive prompt for credentials. Note: This may fail in Windows Terminal with "Error creating window handle" 
        - use DeviceCode parameter instead for Windows Terminal compatibility.

    .PARAMETER Refresh
        Specify to refresh an existing access token.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2021-08-31
        Updated:     2025-12-07

        Version history:
        1.0.0 - (2021-08-31) Script created
        1.0.1 - (2022-03-28) Added ClientSecret parameter input to support client secret auth flow
        1.0.2 - (2022-09-03) Added new global variable to hold the tenant id passed as parameter input for access token refresh scenario
        1.0.3 - (2023-04-07) Added support for client certificate auth flow (thanks to apcsb)
        1.0.4 - (2024-05-29) Updated to integrate New-ClientCredentialsAccessToken function for client secret flow (thanks to @tjgruber)
        1.0.5 - (2025-12-07) BREAKING CHANGE: Removed deprecated Microsoft Intune PowerShell enterprise application fallback, ClientID now mandatory
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
        [parameter(Mandatory = $false, ParameterSetName = "DeviceCode")]
        [ValidateNotNullOrEmpty()]
        [string]$RedirectUri = [string]::Empty,

        [parameter(Mandatory = $false, ParameterSetName = "Interactive", HelpMessage = "Specify to force an interactive prompt for credentials.")]
        [switch]$Interactive,

        [parameter(Mandatory = $true, ParameterSetName = "DeviceCode", HelpMessage = "Specify to do delegated login using devicecode flow, you will be prompted to navigate to https://microsoft.com/devicelogin")]
        [switch]$DeviceCode,

        [parameter(Mandatory = $false, ParameterSetName = "Interactive", HelpMessage = "Specify to refresh an existing access token.")]
        [parameter(Mandatory = $false, ParameterSetName = "DeviceCode")]
        [switch]$Refresh
    )
    Begin {
        # Determine the correct RedirectUri (also known as Reply URL) to use with MSAL.PS
        Write-Verbose -Message "Using Entra ID service principal with Application ID: $($ClientID)"

        # Adjust RedirectUri parameter input in case none was passed on command line
        if ([string]::IsNullOrEmpty($RedirectUri)) {
            switch -Wildcard ($PSVersionTable["PSVersion"]) {
                "5.*" {
                    $RedirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"
                }
                "7.*" {
                    $RedirectUri = "http://localhost"
                }
            }
        }

        Write-Verbose -Message "Using RedirectUri with value: $($RedirectUri)"

        # Set default error action preference configuration
        $ErrorActionPreference = "Stop"
    }
    Process {
        Write-Verbose -Message "Using authentication flow: $($PSCmdlet.ParameterSetName)"

        # Check if the MSAL.PS module is loaded and install if needed
        if (($PSCmdlet.ParameterSetName -ne "ClientSecret") -and (-not (Get-Module -ListAvailable -Name MSAL.PS))) {
            Write-Verbose -Message "MSAL.PS module not found. Installing MSAL.PS module..."
            try {
                Install-Module -Name MSAL.PS -Scope CurrentUser -Force -ErrorAction Stop
                Write-Verbose -Message "MSAL.PS module installed successfully."
            }
            catch {
                Write-Error -Message "Failed to install MSAL.PS module. Error: $_"
                return
            }
        }

        try {
            # Construct table with common parameter input for Get-MsalToken cmdlet
            $AccessTokenArguments = @{
                "TenantId"    = $TenantID
                "ClientId"    = $ClientID
                "RedirectUri" = $RedirectUri
                "ErrorAction" = "Stop"
            }

            # Dynamically add parameter input based on parameter set name
            switch ($PSCmdlet.ParameterSetName) {
                "Interactive" {
                    if ($PSBoundParameters["Refresh"]) {
                        $AccessTokenArguments.Add("ForceRefresh", $true)
                        $AccessTokenArguments.Add("Silent", $true)
                    }
                }
                "DeviceCode" {
                    if ($PSBoundParameters["Refresh"]) {
                        $AccessTokenArguments.Add("ForceRefresh", $true)
                    }
                }
                "ClientSecret" {
                    Write-Verbose "Using clientSecret"
                    try {
                        $Global:AccessToken = New-ClientCredentialsAccessToken -TenantID $TenantID -ClientID $ClientID -ClientSecret $ClientSecret
                        $Global:AccessTokenTenantID = $TenantID
                    }
                    catch {
                        Write-Error "An error occurred while retrieving access token using client credentials: $_"
                        return
                    }
                    $AccessTokenArguments = $null  # Skip MSAL token retrieval
                }
                "ClientCert" {
                    Write-Verbose "Using clientCert"
                    $AccessTokenArguments.Add("ClientCertificate", $ClientCert)
                }
            }

            if ($AccessTokenArguments) {
                # Dynamically add parameter input based on command line input
                if ($PSBoundParameters["Interactive"]) {
                    $AccessTokenArguments.Add("Interactive", $true)
                }
                if ($PSBoundParameters["DeviceCode"]) {
                    if (-not($PSBoundParameters["Refresh"])) {
                        $AccessTokenArguments.Add("DeviceCode", $true)
                    }
                }

                try {
                    # Attempt to retrieve or refresh an access token
                    $Global:AccessToken = Get-MsalToken @AccessTokenArguments
                    $Global:AccessTokenTenantID = $TenantID
                    Write-Verbose -Message "Successfully retrieved access token"
                }
                catch {
                    Write-Warning -Message "An error occurred while attempting to retrieve or refresh access token: $_"
                    return
                }
            }

            try {
                # Construct the required authentication header
                $Global:AuthenticationHeader = New-AuthenticationHeader -AccessToken $Global:AccessToken
                Write-Verbose -Message "Successfully constructed authentication header"

                # Handle return value
                return $Global:AuthenticationHeader
            }
            catch {
                Write-Warning -Message "An error occurred while attempting to construct authentication header: $_"
            }
        }
        catch {
            Write-Warning -Message "An error occurred while constructing parameter input for access token retrieval: $_"
        }
    }
}

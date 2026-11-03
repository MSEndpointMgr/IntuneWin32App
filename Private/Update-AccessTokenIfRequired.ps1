function Update-AccessTokenIfRequired {
    <#
    .SYNOPSIS
        Silently renew the access token when it is about to expire.

    .DESCRIPTION
        Silently renew the access token when it is about to expire. Uses the refresh token for delegated flows (Interactive and DeviceCode),
        and requests a new token using the stored connection details for the ClientSecret, ClientCert and ManagedIdentity flows.
        Throws a terminating error when the token could not be renewed.

    .PARAMETER RenewalThresholdMinutes
        Specify the renewal threshold for access token age in minutes.

    .PARAMETER Force
        Specify to renew the access token regardless of the remaining lifetime.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2026-11-03
        Updated:     2026-11-03

        Version history:
        1.0.0 - (2026-11-03) Function created to support token renewal for all authentication flows (#75, #130, #225)
    #>
    param(
        [parameter(Mandatory = $false, HelpMessage = "Specify the renewal threshold for access token age in minutes.")]
        [int]$RenewalThresholdMinutes = 5,

        [parameter(Mandatory = $false, HelpMessage = "Specify to renew the access token regardless of the remaining lifetime.")]
        [switch]$Force
    )
    Process {
        if (-not($Force) -and (Test-AccessToken -RenewalThresholdMinutes $RenewalThresholdMinutes)) {
            return
        }
        Write-Verbose -Message "Access token requires renewal"

        $Connection = $Script:IntuneGraphConnection
        $TenantID = if ($null -ne $Connection) { $Connection.TenantID } else { $Global:AccessTokenTenantID }
        $ClientID = if ($null -ne $Connection) { $Connection.ClientID } else { $Global:AccessTokenClientID }
        $Flow = if ($null -ne $Connection) { $Connection.Flow } else { [string]::Empty }
        $HasRefreshToken = ($null -ne $Global:AccessToken) -and ($Global:AccessToken.PSObject.Properties["RefreshToken"]) -and (-not([string]::IsNullOrEmpty($Global:AccessToken.RefreshToken)))

        if ($HasRefreshToken -and -not([string]::IsNullOrEmpty($ClientID))) {
            $RenewalMethod = "RefreshToken"
        }
        elseif ($Flow -in @("ClientSecret", "ClientCert", "ManagedIdentity")) {
            $RenewalMethod = $Flow
        }
        else {
            # Token cannot be renewed, continue using it until it has actually expired
            $ExpiresOnUTC = Get-AccessTokenExpiryUTC
            if (($null -ne $ExpiresOnUTC) -and ($ExpiresOnUTC -gt [DateTimeOffset]::UtcNow)) {
                Write-Verbose -Message "Access token cannot be renewed silently, continuing with existing token until it expires"
                return
            }
            throw "Access token has expired and cannot be renewed silently, no refresh token or client credentials are available. Please re-authenticate using Connect-MSIntuneGraph"
        }

        try {
            Write-Verbose -Message "Attempting silent token renewal using method: $($RenewalMethod)"
            switch ($RenewalMethod) {
                "RefreshToken" {
                    $Scopes = if ($Global:AccessToken.PSObject.Properties["Scopes"] -and $Global:AccessToken.Scopes) { $Global:AccessToken.Scopes } else { @("DeviceManagementApps.ReadWrite.All") }
                    if ($Scopes -notcontains "offline_access") {
                        $Scopes = @($Scopes) + "offline_access"
                    }
                    $null = Update-AccessTokenFromRefreshToken -TenantID $TenantID -ClientID $ClientID -RefreshToken $Global:AccessToken.RefreshToken -Scopes $Scopes
                }
                "ClientSecret" {
                    $null = New-ClientCredentialsAccessToken -TenantID $TenantID -ClientID $ClientID -ClientSecret $Connection.ClientSecret
                }
                "ClientCert" {
                    $null = New-ClientCertificateAccessToken -TenantID $TenantID -ClientID $ClientID -ClientCertificate $Connection.ClientCert
                }
                "ManagedIdentity" {
                    $null = New-ManagedIdentityAccessToken -ClientID $Connection.ManagedIdentityClientID
                }
            }
        }
        catch {
            throw "Silent token renewal failed: $($_). Please re-authenticate using Connect-MSIntuneGraph"
        }

        # Update authentication header with the renewed token
        $Global:AuthenticationHeader = New-AuthenticationHeader -AccessToken $Global:AccessToken
        Write-Verbose -Message "Successfully renewed access token silently"
    }
}

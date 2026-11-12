function Update-AccessToken {
    <#
    .SYNOPSIS
        Renew the current access token without user interaction.

    .DESCRIPTION
        Renew the current access token without user interaction and update the global access token and authentication header.

        A token retrieved with the Interactive or DeviceCode flow is renewed using its refresh token. A token retrieved with
        the ClientSecret or ClientCert flow has no refresh token, and is instead requested again using the credentials passed
        to the Connect-MSIntuneGraph function.

        Returns $true when the access token was renewed, otherwise $false.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2026-11-12
        Updated:     2026-11-12

        Version history:
        1.0.0 - (2026-11-12) Function created
    #>
    [OutputType([System.Boolean])]
    param()
    Process {
        $RenewalContext = $Script:AccessTokenRenewalContext
        $TenantID = $Global:AccessTokenTenantID

        try {
            if ($null -ne $Global:AccessToken -and $Global:AccessToken.PSObject.Properties["RefreshToken"] -and -not [string]::IsNullOrEmpty($Global:AccessToken.RefreshToken)) {
                # Determine the client ID, either from the access token itself or from the last call to Connect-MSIntuneGraph
                $ClientID = $null
                if ($Global:AccessToken.PSObject.Properties["client_id"] -and -not [string]::IsNullOrEmpty($Global:AccessToken.client_id)) {
                    $ClientID = $Global:AccessToken.client_id
                }
                elseif ($null -ne $RenewalContext) {
                    $ClientID = $RenewalContext["ClientID"]
                }

                if ([string]::IsNullOrEmpty($ClientID) -or [string]::IsNullOrEmpty($TenantID)) {
                    Write-Warning -Message "Silent token refresh failed: Unable to determine the tenant and client ID of the current access token"
                    return $false
                }

                $Scopes = if ($Global:AccessToken.PSObject.Properties["Scopes"]) {
                    $Global:AccessToken.Scopes
                }
                else {
                    @("DeviceManagementApps.ReadWrite.All", "offline_access")
                }

                Write-Verbose -Message "Attempting silent token refresh"
                $null = Update-AccessTokenFromRefreshToken -TenantID $TenantID -ClientID $ClientID -RefreshToken $Global:AccessToken.RefreshToken -Scopes $Scopes
            }
            elseif ($null -ne $RenewalContext -and $null -ne $RenewalContext["ClientCert"]) {
                Write-Verbose -Message "Attempting to request a new access token using client certificate"
                $null = New-ClientCertificateAccessToken -TenantID $RenewalContext["TenantID"] -ClientID $RenewalContext["ClientID"] -ClientCertificate $RenewalContext["ClientCert"]
            }
            elseif ($null -ne $RenewalContext -and -not [string]::IsNullOrEmpty($RenewalContext["ClientSecret"])) {
                Write-Verbose -Message "Attempting to request a new access token using client credentials"
                $null = New-ClientCredentialsAccessToken -TenantID $RenewalContext["TenantID"] -ClientID $RenewalContext["ClientID"] -ClientSecret $RenewalContext["ClientSecret"]
            }
            else {
                Write-Verbose -Message "Access token can't be renewed, neither a refresh token nor client credentials are available"
                return $false
            }

            # Update authentication header with new token
            $Global:AuthenticationHeader = New-AuthenticationHeader -AccessToken $Global:AccessToken
            Write-Verbose -Message "Successfully renewed access token"
            return $true
        }
        catch {
            Write-Warning -Message "Silent token refresh failed: $($_)"
            return $false
        }
    }
}

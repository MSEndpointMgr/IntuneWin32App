function New-DeviceCodeAccessToken {
    <#
    .SYNOPSIS
        Requests an access token using the OAuth 2.0 device code flow.

    .DESCRIPTION
        Requests an access token using the OAuth 2.0 device code flow.
        This function initiates a device code flow and displays a user code that must be entered at a verification URL.

    .PARAMETER TenantID
        Tenant ID of the Entra ID tenant.

    .PARAMETER ClientID
        Application ID (Client ID) for an Entra ID service principal.

    .PARAMETER Scopes
        Array of permission scopes to request. Defaults to DeviceManagementApps.ReadWrite.All.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2026-01-02
        Updated:     2026-01-04

        Version history:
        1.0.0 - (2026-01-02) Script created
        1.0.1 - (2026-01-04) Added refresh token storage for silent token renewal
    #>
    param(
        [parameter(Mandatory = $true, HelpMessage = "Tenant ID of the Entra ID tenant.")]
        [ValidateNotNullOrEmpty()]
        [String]$TenantID,

        [parameter(Mandatory = $true, HelpMessage = "Application ID (Client ID) for an Entra ID service principal.")]
        [ValidateNotNullOrEmpty()]
        [String]$ClientID,

        [parameter(Mandatory = $false, HelpMessage = "Array of permission scopes to request.")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Scopes = @("DeviceManagementApps.ReadWrite.All", "DeviceManagementRBAC.Read.All", "offline_access")
    )
    Process {
        try {
            # Request device code
            $DeviceCodeUri = "https://login.microsoftonline.com/$($TenantID)/oauth2/v2.0/devicecode"
            $ScopeString = $Scopes -join " "
            
            $DeviceCodeBody = @{
                "client_id" = $ClientID
                "scope" = $ScopeString
            }

            Write-Verbose -Message "Requesting device code from Azure AD"
            $DeviceCodeResponse = Invoke-RestMethod -Method Post -Uri $DeviceCodeUri -Body $DeviceCodeBody -ErrorAction Stop

            # Display user code and verification URL
            Write-Host "To sign in, use a web browser to open the page: $($DeviceCodeResponse.verification_uri)"
            Write-Host "And enter the code: $($DeviceCodeResponse.user_code)"
            Write-Verbose -Message "Device code expires in $($DeviceCodeResponse.expires_in) seconds"
            Write-Verbose -Message "Polling interval: $($DeviceCodeResponse.interval) seconds"

            # Poll for token
            $TokenUri = "https://login.microsoftonline.com/$($TenantID)/oauth2/v2.0/token"
            $TokenBody = @{
                "client_id" = $ClientID
                "grant_type" = "urn:ietf:params:oauth:grant-type:device_code"
                "device_code" = $DeviceCodeResponse.device_code
            }

            # Initialize polling variables
            $PollInterval = $DeviceCodeResponse.interval
            $ExpiresIn = $DeviceCodeResponse.expires_in
            $StartTime = Get-Date
            $TokenAcquired = $false

            Write-Verbose -Message "Waiting for user to complete authentication"

            while (-not $TokenAcquired) {
                # Check if device code has expired
                $ElapsedSeconds = ((Get-Date) - $StartTime).TotalSeconds
                if ($ElapsedSeconds -ge $ExpiresIn) {
                    throw "Device code has expired. Please run the command again."
                }

                # Wait for the polling interval
                Start-Sleep -Seconds $PollInterval

                try {
                    # Attempt to retrieve token
                    $TokenResponse = Invoke-RestMethod -Method Post -Uri $TokenUri -Body $TokenBody -ErrorAction Stop
                    $TokenAcquired = $true
                    Write-Verbose -Message "Successfully acquired access token"
                }
                catch {
                    $ErrorResponse = $_.Exception.Response
                    if ($ErrorResponse) {
                        $Reader = New-Object System.IO.StreamReader($ErrorResponse.GetResponseStream())
                        $Reader.BaseStream.Position = 0
                        $ResponseBody = $Reader.ReadToEnd() | ConvertFrom-Json
                        
                        switch ($ResponseBody.error) {
                            "authorization_pending" {
                                Write-Verbose -Message "Authorization pending, continuing to poll"
                                continue
                            }
                            "slow_down" {
                                Write-Verbose -Message "Polling too frequently, increasing interval"
                                $PollInterval += 5
                                continue
                            }
                            "authorization_declined" {
                                throw "User declined the authorization request"
                            }
                            "expired_token" {
                                throw "Device code has expired"
                            }
                            default {
                                throw "Authentication error: $($ResponseBody.error) - $($ResponseBody.error_description)"
                            }
                        }
                    }
                    else {
                        throw "Error retrieving access token: $($_)"
                    }
                }
            }

            # Validate the result
            if (-not $TokenResponse.access_token) {
                throw "No access token was returned in the response"
            }

            Write-Host "Authentication successful"

            # Add ExpiresOn property for token expiration tracking
            $TokenResponse | Add-Member -MemberType NoteProperty -Name "ExpiresOn" -Value ((Get-Date).AddSeconds($TokenResponse.expires_in).ToUniversalTime()) -Force
            
            # Add Scopes property for permission tracking
            $TokenResponse | Add-Member -MemberType NoteProperty -Name "Scopes" -Value ($TokenResponse.scope -split " ") -Force
            
            # Add AccessToken property for consistent access
            $TokenResponse | Add-Member -MemberType NoteProperty -Name "AccessToken" -Value $TokenResponse.access_token -Force
            
            # Store refresh token if available for silent token renewal
            if ($TokenResponse.refresh_token) {
                $TokenResponse | Add-Member -MemberType NoteProperty -Name "RefreshToken" -Value $TokenResponse.refresh_token -Force
                Write-Verbose -Message "Refresh token stored for silent token renewal"
            }

            # Set global variable
            $Global:AccessToken = $TokenResponse
        }
        catch {
            throw "Error retrieving the access token: $($_)"
        }
    }
}

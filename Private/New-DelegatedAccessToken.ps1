function New-DelegatedAccessToken {
    <#
    .SYNOPSIS
        Requests an access token using the delegated OAuth 2.0 authorization code flow with PKCE.

    .DESCRIPTION
        Requests an access token using the delegated OAuth 2.0 authorization code flow with PKCE (Proof Key for Code Exchange).
        This function opens a browser for interactive user authentication and exchanges the authorization code for an access token.

    .PARAMETER TenantID
        Tenant ID of the Entra ID tenant.

    .PARAMETER ClientID
        Application ID (Client ID) for an Entra ID service principal.

    .PARAMETER RedirectUri
        Redirect URI configured in the Entra ID app registration. Defaults to http://localhost.

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

        [parameter(Mandatory = $false, HelpMessage = "Redirect URI configured in the Entra ID app registration.")]
        [ValidateNotNullOrEmpty()]
        [String]$RedirectUri = "http://localhost",

        [parameter(Mandatory = $false, HelpMessage = "Array of permission scopes to request.")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Scopes = @("DeviceManagementApps.ReadWrite.All", "DeviceManagementRBAC.Read.All", "offline_access")
    )
    Process {
        try {
            # Load required assembly for query string parsing
            Add-Type -AssemblyName System.Web
            
            # Generate PKCE code verifier and challenge
            # Use RNGCryptoServiceProvider for PowerShell 5.1 compatibility
            $RandomBytes = New-Object byte[] 32
            $RNG = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
            $RNG.GetBytes($RandomBytes)
            $RNG.Dispose()
            
            $CodeVerifier = [Convert]::ToBase64String($RandomBytes)
            $CodeVerifier = $CodeVerifier.Replace("+", "-").Replace("/", "_").Replace("=", "")
            
            $SHA256 = [System.Security.Cryptography.SHA256]::Create()
            $CodeChallenge = [Convert]::ToBase64String($SHA256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($CodeVerifier)))
            $CodeChallenge = $CodeChallenge.Replace("+", "-").Replace("/", "_").Replace("=", "")
            $SHA256.Dispose()

            # Generate state parameter for CSRF protection
            $State = [Guid]::NewGuid().ToString()

            # Start local HTTP listener on dynamic port
            # Bind to any available port, then use that in the redirect URI
            $HttpListener = New-Object System.Net.HttpListener
            
            # Find an available port by binding to port 0 (auto-assign)
            $TcpListener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, 0)
            $TcpListener.Start()
            $Port = $TcpListener.LocalEndpoint.Port
            $TcpListener.Stop()
            
            # Build the actual redirect URI with the dynamically assigned port
            $ActualRedirectUri = "http://localhost:$($Port)/"
            $HttpListener.Prefixes.Add($ActualRedirectUri)
            
            try {
                $HttpListener.Start()
                Write-Verbose -Message "HTTP listener started on $($ActualRedirectUri)"
            }
            catch {
                throw "Failed to start HTTP listener on $($ActualRedirectUri). Error: $($_)"
            }

            # Build authorization URL using the dynamic redirect URI
            $AuthorizationUri = "https://login.microsoftonline.com/$($TenantID)/oauth2/v2.0/authorize"
            $ScopeString = $Scopes -join " "
            
            # Use the actual redirect URI with port in the authorization request
            $AuthUrl = "$AuthorizationUri`?client_id=$ClientID&response_type=code&redirect_uri=$([System.Uri]::EscapeDataString($ActualRedirectUri.TrimEnd('/')))&response_mode=query&scope=$([System.Uri]::EscapeDataString($ScopeString))&state=$State&code_challenge=$CodeChallenge&code_challenge_method=S256&prompt=select_account"

            # Open browser for user authentication
            Write-Verbose -Message "Opening browser for authentication. Please sign in"
            Start-Process $AuthUrl

            # Wait for callback
            Write-Verbose -Message "Waiting for authentication callback"
            
            try {
                # Wait for the browser callback with authorization code
                $Context = $HttpListener.GetContext()
                $Request = $Context.Request
                $Response = $Context.Response

                Write-Verbose -Message "Received authentication callback"

                # Extract authorization code and state from query string
                $QueryParams = [System.Web.HttpUtility]::ParseQueryString($Request.Url.Query)
                $AuthCode = $QueryParams["code"]
                $ReturnedState = $QueryParams["state"]
                $ErrorCode = $QueryParams["error"]
                $ErrorDescription = $QueryParams["error_description"]

                # Send response to browser
                if ($AuthCode) {
                    $Response.StatusCode = 200
                    $ResponseString = "<html><head><title>Authentication Successful</title></head><body style='font-family: Arial, sans-serif; text-align: center; padding: 50px;'><h1 style='color: green;'>Authentication Successful</h1><p>You have successfully authenticated.</p><p>You can close this window and return to PowerShell.</p></body></html>"
                }
                elseif ($ErrorCode) {
                    # Set appropriate HTTP status code based on OAuth error type
                    switch ($ErrorCode) {
                        "access_denied" {
                            $Response.StatusCode = 403
                        }
                        "unauthorized_client" {
                            $Response.StatusCode = 401
                        }
                        "invalid_request" {
                            $Response.StatusCode = 400
                        }
                        "unsupported_response_type" {
                            $Response.StatusCode = 400
                        }
                        "invalid_scope" {
                            $Response.StatusCode = 400
                        }
                        "server_error" {
                            $Response.StatusCode = 500
                        }
                        "temporarily_unavailable" {
                            $Response.StatusCode = 503
                        }
                        default {
                            $Response.StatusCode = 400
                        }
                    }
                    $ResponseString = "<html><head><title>Authentication Failed</title></head><body style='font-family: Arial, sans-serif; text-align: center; padding: 50px;'><h1 style='color: red;'>Authentication Failed</h1><p>Error: $($ErrorDescription)</p><p>Error Code: $($ErrorCode)</p><p>You can close this window and try again.</p></body></html>"
                }
                else {
                    $Response.StatusCode = 400
                    $ResponseString = "<html><head><title>Authentication Failed</title></head><body style='font-family: Arial, sans-serif; text-align: center; padding: 50px;'><h1 style='color: red;'>Authentication Failed</h1><p>No authorization code or error received.</p><p>You can close this window and try again.</p></body></html>"
                }
                
                $Buffer = [System.Text.Encoding]::UTF8.GetBytes($ResponseString)
                $Response.ContentLength64 = $Buffer.Length
                $Response.ContentType = "text/html; charset=utf-8"
                $Response.KeepAlive = $false
                
                try {
                    $Response.OutputStream.Write($Buffer, 0, $Buffer.Length)
                    $Response.OutputStream.Flush()
                }
                finally {
                    $Response.OutputStream.Close()
                }
                
                $Response.Close()
            }
            catch {
                throw "Failed to process authentication callback: $($_)"
            }
            finally {
                # Give time for response to be delivered before stopping listener
                Start-Sleep -Seconds 3
                
                # Always stop the listener
                if ($HttpListener.IsListening) {
                    $HttpListener.Stop()
                }
                $HttpListener.Close()
            }

            # Validate response
            if ($ErrorCode) {
                throw "Authentication error: $($ErrorCode) - $($ErrorDescription)"
            }

            if ($ReturnedState -ne $State) {
                throw "State mismatch - possible CSRF attack detected. Expected: $($State), Received: $($ReturnedState)"
            }

            if (-not $AuthCode) {
                throw "No authorization code received in callback"
            }

            # Exchange authorization code for access token
            $TokenUri = "https://login.microsoftonline.com/$($TenantID)/oauth2/v2.0/token"
            $TokenBody = @{
                "client_id" = $ClientID
                "scope" = $ScopeString
                "code" = $AuthCode
                "redirect_uri" = $ActualRedirectUri.TrimEnd('/')
                "grant_type" = "authorization_code"
                "code_verifier" = $CodeVerifier
            }

            Write-Verbose -Message "Exchanging authorization code for access token"
            $TokenResponse = Invoke-RestMethod -Method Post -Uri $TokenUri -Body $TokenBody -ErrorAction Stop

            # Validate the result
            if (-not $TokenResponse.access_token) {
                throw "No access token was returned in the response."
            }

            Write-Verbose -Message "Authentication successful"

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

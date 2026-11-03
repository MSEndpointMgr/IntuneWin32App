function New-ManagedIdentityAccessToken {
    <#
    .SYNOPSIS
        Requests an access token for Microsoft Graph using an Azure managed identity.

    .DESCRIPTION
        Requests an access token for Microsoft Graph using an Azure managed identity. Supports Azure App Service, Azure Functions and
        Azure Automation (IDENTITY_ENDPOINT and IDENTITY_HEADER environment variables), Azure Arc and Azure Virtual Machines (Instance Metadata Service).

    .PARAMETER ClientID
        Client ID of a user-assigned managed identity. Leave empty to use the system-assigned managed identity.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2026-11-03
        Updated:     2026-11-03

        Version history:
        1.0.0 - (2026-11-03) Function created (#201)
    #>
    param(
        [parameter(Mandatory = $false, HelpMessage = "Client ID of a user-assigned managed identity. Leave empty to use the system-assigned managed identity.")]
        [string]$ClientID = [string]::Empty
    )
    Process {
        $Resource = "https://graph.microsoft.com"

        if (-not([string]::IsNullOrEmpty($env:IDENTITY_ENDPOINT)) -and -not([string]::IsNullOrEmpty($env:IDENTITY_HEADER))) {
            # Azure App Service, Azure Functions and Azure Automation
            Write-Verbose -Message "Using managed identity endpoint from IDENTITY_ENDPOINT environment variable"
            $TokenUri = "$($env:IDENTITY_ENDPOINT)?resource=$([System.Uri]::EscapeDataString($Resource))&api-version=2019-08-01"
            if (-not([string]::IsNullOrEmpty($ClientID))) {
                $TokenUri += "&client_id=$([System.Uri]::EscapeDataString($ClientID))"
            }
            $Headers = @{ "X-IDENTITY-HEADER" = $env:IDENTITY_HEADER; "Metadata" = "true" }
        }
        else {
            # Azure Virtual Machines and Azure Arc, using the Instance Metadata Service
            Write-Verbose -Message "Using Azure Instance Metadata Service managed identity endpoint"
            $TokenEndpoint = if (-not([string]::IsNullOrEmpty($env:IDENTITY_ENDPOINT))) { $env:IDENTITY_ENDPOINT } else { "http://169.254.169.254/metadata/identity/oauth2/token" }
            $TokenUri = "$($TokenEndpoint)?resource=$([System.Uri]::EscapeDataString($Resource))&api-version=2019-08-01"
            if (-not([string]::IsNullOrEmpty($ClientID))) {
                $TokenUri += "&client_id=$([System.Uri]::EscapeDataString($ClientID))"
            }
            $Headers = @{ "Metadata" = "true" }
        }

        try {
            $TokenResponse = Invoke-RestMethod -Method Get -Uri $TokenUri -Headers $Headers -ErrorAction Stop
        }
        catch {
            # Azure Arc requires a challenge response, where the secret is read from a local file referenced in the WWW-Authenticate header
            $ChallengeHeader = $null
            if ($_.Exception.Response) {
                $ChallengeHeader = try { $_.Exception.Response.Headers["WWW-Authenticate"] } catch { $null }
                if (($null -eq $ChallengeHeader) -and ($_.Exception.Response.Headers.WwwAuthenticate)) {
                    $ChallengeHeader = $_.Exception.Response.Headers.WwwAuthenticate.Parameter
                }
            }
            if (($null -ne $ChallengeHeader) -and ("$($ChallengeHeader)" -match "realm=(.+)$|^(.+\.key)$")) {
                $SecretFilePath = if ($Matches[1]) { $Matches[1] } else { $Matches[2] }
                $Secret = Get-Content -LiteralPath $SecretFilePath.Trim() -Raw -ErrorAction Stop
                $Headers["Authorization"] = "Basic $($Secret.Trim())"
                $TokenResponse = Invoke-RestMethod -Method Get -Uri $TokenUri -Headers $Headers -ErrorAction Stop
            }
            else {
                throw "Failed to retrieve access token using managed identity: $($_)"
            }
        }

        if (-not($TokenResponse.access_token)) {
            throw "No access token was returned in the managed identity response"
        }

        # Managed identity endpoints return expires_on as Unix time in seconds, fall back to expires_in when not present
        if ($TokenResponse.expires_on -match "^\d+$") {
            $ExpiresOn = [DateTimeOffset]::FromUnixTimeSeconds([int64]$TokenResponse.expires_on).UtcDateTime
        }
        else {
            $ExpiresOn = (Get-Date).AddSeconds([int]$TokenResponse.expires_in).ToUniversalTime()
        }

        $TokenResponse | Add-Member -MemberType NoteProperty -Name "ExpiresOn" -Value $ExpiresOn -Force
        $TokenResponse | Add-Member -MemberType NoteProperty -Name "Scopes" -Value @("https://graph.microsoft.com/.default") -Force
        $TokenResponse | Add-Member -MemberType NoteProperty -Name "AccessToken" -Value $TokenResponse.access_token -Force

        # Set global variable
        $Global:AccessToken = $TokenResponse
    }
}

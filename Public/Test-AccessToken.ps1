function Test-AccessToken {
    <#
    .SYNOPSIS
        Use to check if the existing access token is about to expire.

    .DESCRIPTION
        Use to check if the existing access token is about to expire.

    .PARAMETER RenewalThresholdMinutes
        Specify the renewal threshold for access token age in minutes.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2021-04-08
        Updated:     2024-11-15

        Version history:
        1.0.0 - (2021-04-08) Script created
        1.0.1 - (2023-09-04) Updated to use TotalMinutes instead of Minutes property, which would cause for inaccurate results
        1.0.2 - (2024-03-07) Invocation of function when access token is null will now return false
        1.0.3 - (2024-05-29) Updated to handle tokens with ExpiresOn property (thanks to @tjgruber)
        1.0.4 - (2024-11-15) Refactor date handling for token to fix locale-specific parsing issues (thanks to @tjgruber)
        1.0.5 - (2025-12-07) Reduced default RenewalThresholdMinutes from 10 to 5 minutes to avoid conflicts with minimum Access Token Lifetime policies
    #>
    param(
        [parameter(Mandatory = $false, HelpMessage = "Specify the renewal threshold for access token age in minutes.")]
        [ValidateNotNullOrEmpty()]
        [int]$RenewalThresholdMinutes = 5
    )
    Process {
        if ($null -eq $Global:AccessToken) {
            return $false
        }
        else {
            # Determine the current time in UTC
            $UTCDateTime = (Get-Date).ToUniversalTime()

            # Calculate the expiration time of the token
            if ($Global:AccessToken.PSObject.Properties["ExpiresOn"] -and $Global:AccessToken.ExpiresOn) {
                $ExpiresOn = $Global:AccessToken.ExpiresOn.ToUniversalTime()
            }
            else {
                Write-Verbose -Message "The access token does not contain a valid ExpiresOn property. Cannot determine expiration."
                return $false
            }

            # Convert ExpiresOn to DateTimeOffset in UTC
            $ExpiresOnUTC = [DateTimeOffset]::Parse($Global:AccessToken.ExpiresOn.ToString([System.Globalization.CultureInfo]::InvariantCulture), [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AssumeUniversal).ToUniversalTime()

            # Get the current UTC time as DateTimeOffset
            $UTCDateTime = [DateTimeOffset]::UtcNow

            # Calculate the TimeSpan between expiration and current time
            $TimeSpan = $ExpiresOnUTC - $UTCDateTime

            # Calculate the token expiration time in minutes
            $TokenExpireMinutes = [System.Math]::Round($TimeSpan.TotalMinutes)

            # Determine if refresh of access token is required when expiration count is less than or equal to minimum age
            if ($TokenExpireMinutes -le $RenewalThresholdMinutes) {
                Write-Verbose -Message "Access token refresh is required, current token expires in (minutes): $($TokenExpireMinutes)"
                return $false
            }
            else {
                # Only show verbose output if token expires within 10 minutes to reduce noise
                if ($TokenExpireMinutes -le 10) {
                    Write-Verbose -Message "Access token refresh is not required, remaining minutes until expiration: $($TokenExpireMinutes)"
                }
                return $true
            }
        }
    }
}

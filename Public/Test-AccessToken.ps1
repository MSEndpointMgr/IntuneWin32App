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
        Updated:     2024-03-07

        Version history:
        1.0.0 - (2021-04-08) Script created
        1.0.1 - (2023-09-04) Updated to use TotalMinutes instead of Minutes property, which would cause for inaccurate results
        1.0.2 - (2024-03-07) Invocation of function when access token is null will now return false
    #>
    param(
        [parameter(Mandatory = $false, HelpMessage = "Specify the renewal threshold for access token age in minutes.")]
        [ValidateNotNullOrEmpty()]
        [int]$RenewalThresholdMinutes = 10
    )
    Process {
        if ($Global:AccessToken -eq $null) {
            return $false
        }
        else {
            # Determine the current time in UTC
            $UTCDateTime = (Get-Date).ToUniversalTime()
                                
            # Determine the token expiration count as minutes
            $TokenExpireMinutes = [System.Math]::Round(([datetime]$Global:AccessToken.ExpiresOn.ToUniversalTime().UtcDateTime - $UTCDateTime).TotalMinutes)

            # Determine if refresh of access token is required when expiration count is less than or equal to minimum age
            if ($TokenExpireMinutes -le $RenewalThresholdMinutes) {
                Write-Verbose -Message "Access token refresh is required, current token expires in (minutes): $($TokenExpireMinutes)"
                return $false
            }
            else {
                Write-Verbose -Message "Access token refresh is not required, remaining minutes until expiration: $($TokenExpireMinutes)"
                return $true
            }
        }
    }
}
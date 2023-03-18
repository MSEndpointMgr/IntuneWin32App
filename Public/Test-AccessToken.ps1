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
        Updated:     2021-04-08

        Version history:
        1.0.0 - (2021-04-08) Script created
    #>
    param(
        [parameter(Mandatory = $false, HelpMessage = "Specify the renewal threshold for access token age in minutes.")]
        [ValidateNotNullOrEmpty()]
        [int]$RenewalThresholdMinutes = 10
    )
    Process {
        # Determine the current time in UTC
        $UTCDateTime = (Get-Date).ToUniversalTime()
                    
        # Determine the token expiration count as minutes
        $TokenExpireMinutes = ([datetime]$Global:AccessToken.ExpiresOn.ToUniversalTime().UtcDateTime - $UTCDateTime).Minutes

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
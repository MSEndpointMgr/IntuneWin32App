function Get-AccessTokenExpiryUTC {
    <#
    .SYNOPSIS
        Get the expiration time of the current access token as a UTC DateTimeOffset object.

    .DESCRIPTION
        Get the expiration time of the current access token as a UTC DateTimeOffset object.
        The ExpiresOn property is never converted to a culture specific string and parsed back, since that results in
        day and month being swapped on systems using a non en-US date format (e.g. de-DE, en-AU, en-GB, fr-FR).

    .PARAMETER AccessToken
        Specify the access token object, defaults to the global access token.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2026-11-03
        Updated:     2026-11-03

        Version history:
        1.0.0 - (2026-11-03) Function created to fix locale specific date parsing issues (#210, #225, #238)
    #>
    param(
        [parameter(Mandatory = $false, HelpMessage = "Specify the access token object, defaults to the global access token.")]
        $AccessToken = $Global:AccessToken
    )
    Process {
        if ($null -eq $AccessToken) {
            return $null
        }

        if (-not($AccessToken.PSObject.Properties["ExpiresOn"]) -or ($null -eq $AccessToken.ExpiresOn)) {
            return $null
        }

        $ExpiresOn = $AccessToken.ExpiresOn
        switch ($ExpiresOn.GetType().FullName) {
            "System.DateTimeOffset" {
                return $ExpiresOn.ToUniversalTime()
            }
            "System.DateTime" {
                # ExpiresOn is set with ToUniversalTime() by the token functions, treat unspecified kind as UTC as well
                if ($ExpiresOn.Kind -eq [System.DateTimeKind]::Local) {
                    return ([DateTimeOffset]$ExpiresOn).ToUniversalTime()
                }
                return [DateTimeOffset]::new([DateTime]::SpecifyKind($ExpiresOn, [System.DateTimeKind]::Utc))
            }
            default {
                # Handle string values, e.g. when a token object was serialized and restored. Strings produced on this system use the current culture,
                # ISO 8601 strings parse correctly with either culture
                $ParsedDateTime = [DateTimeOffset]::MinValue
                $DateTimeStyles = [System.Globalization.DateTimeStyles]::AssumeUniversal -bor [System.Globalization.DateTimeStyles]::AdjustToUniversal
                foreach ($Culture in @([System.Globalization.CultureInfo]::CurrentCulture, [System.Globalization.CultureInfo]::InvariantCulture)) {
                    if ([DateTimeOffset]::TryParse([string]$ExpiresOn, $Culture, $DateTimeStyles, [ref]$ParsedDateTime)) {
                        return $ParsedDateTime.ToUniversalTime()
                    }
                }
                Write-Verbose -Message "Unable to parse ExpiresOn value of access token: $($ExpiresOn)"
                return $null
            }
        }
    }
}

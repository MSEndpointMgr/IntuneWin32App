function ConvertTo-UTCDateTimeOffset {
    <#
    .SYNOPSIS
        Convert a date and time value to a DateTimeOffset in UTC, independent of the current culture.

    .DESCRIPTION
        Convert a date and time value to a DateTimeOffset in UTC, independent of the current culture.

        DateTime and DateTimeOffset values are converted directly, without a round trip through a string representation.
        Such a round trip depends on the current culture and returns a wrong date for cultures that use another date
        format or calendar than the invariant culture, e.g. en-GB or de-DE.

    .PARAMETER InputObject
        Specify the date and time value to convert, either as a DateTime, DateTimeOffset or string object.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2026-11-12
        Updated:     2026-11-12

        Version history:
        1.0.0 - (2026-11-12) Function created
    #>
    [OutputType([System.DateTimeOffset])]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the date and time value to convert, either as a DateTime, DateTimeOffset or string object.")]
        [ValidateNotNull()]
        [object]$InputObject
    )
    Process {
        # Unwrap the value in case it's wrapped in a PSObject, e.g. when it comes from a deserialized object
        if ($InputObject -is [System.Management.Automation.PSObject]) {
            $InputObject = $InputObject.PSObject.BaseObject
        }

        if ($InputObject -is [System.DateTimeOffset]) {
            return $InputObject.ToUniversalTime()
        }
        elseif ($InputObject -is [System.DateTime]) {
            if ($InputObject.Kind -eq [System.DateTimeKind]::Local) {
                return ([System.DateTimeOffset]$InputObject).ToUniversalTime()
            }
            else {
                # Treat a value of an unspecified kind as UTC, since all access token functions in this module store the expiration time in UTC
                return New-Object -TypeName "System.DateTimeOffset" -ArgumentList @([System.DateTime]::SpecifyKind($InputObject, [System.DateTimeKind]::Utc))
            }
        }
        else {
            # Parse any other value as a string, attempt the invariant culture first and fall back to the current culture
            $ParsedValue = [System.DateTimeOffset]::MinValue
            $DateTimeStyles = [System.Globalization.DateTimeStyles]::AssumeUniversal
            foreach ($Culture in @([System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.CultureInfo]::CurrentCulture)) {
                if ([System.DateTimeOffset]::TryParse([string]$InputObject, $Culture, $DateTimeStyles, [ref]$ParsedValue)) {
                    return $ParsedValue.ToUniversalTime()
                }
            }
            throw "Unable to convert value '$($InputObject)' to a valid date and time"
        }
    }
}

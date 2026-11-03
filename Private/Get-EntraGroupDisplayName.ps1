function Get-EntraGroupDisplayName {
    <#
    .SYNOPSIS
        Resolve the display name of an Entra ID group, including soft-deleted groups.

    .DESCRIPTION
        Resolve the display name of an Entra ID group, including soft-deleted groups. Results are cached per session to avoid
        repeated requests when multiple assignments target the same group.

    .PARAMETER GroupID
        Specify the object ID of the group.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2026-11-03
        Updated:     2026-11-03

        Version history:
        1.0.0 - (2026-11-03) Function created (#108, #211)
    #>
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the object ID of the group.")]
        [ValidateNotNullOrEmpty()]
        [string]$GroupID
    )
    Process {
        if ($null -eq $Script:EntraGroupDisplayNameCache) {
            $Script:EntraGroupDisplayNameCache = @{}
        }
        if ($Script:EntraGroupDisplayNameCache.ContainsKey($GroupID)) {
            return $Script:EntraGroupDisplayNameCache[$GroupID]
        }

        # Retrieve active group, a missing group is expected when it has been deleted so warnings are suppressed
        $DisplayName = $null
        $GroupResponse = Invoke-MSGraphOperation -Get -APIVersion "v1.0" -Resource "groups/$($GroupID)?`$select=id,displayName" -WarningAction "SilentlyContinue"
        if (($null -ne $GroupResponse) -and -not([string]::IsNullOrEmpty($GroupResponse.displayName))) {
            $DisplayName = $GroupResponse.displayName
        }
        else {
            # Group was not found, attempt to retrieve it from deleted items for soft-deleted groups
            $DeletedGroupResponse = Invoke-MSGraphOperation -Get -APIVersion "v1.0" -Resource "directory/deletedItems/$($GroupID)" -WarningAction "SilentlyContinue"
            if (($null -ne $DeletedGroupResponse) -and -not([string]::IsNullOrEmpty($DeletedGroupResponse.displayName))) {
                $DisplayName = "$($DeletedGroupResponse.displayName) (deleted)"
            }
            else {
                Write-Verbose -Message "Unable to resolve display name for group with ID: $($GroupID)"
            }
        }

        # Only cache resolved names, so transient failures are retried on the next lookup
        if ($null -ne $DisplayName) {
            $Script:EntraGroupDisplayNameCache[$GroupID] = $DisplayName
        }
        return $DisplayName
    }
}

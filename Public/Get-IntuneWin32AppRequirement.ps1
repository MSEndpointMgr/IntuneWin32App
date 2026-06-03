function Get-IntuneWin32AppRequirement {
    <#
    .SYNOPSIS
        Retrieve additional requirement rules from an existing Win32 application.

    .DESCRIPTION
        Retrieve additional requirement rules from an existing Win32 application.
        Returns the requirementRules array (file, registry or script based rules) as configured
        on the app. Does not return the primary requirement rule (architecture, OS version, disk, memory).

    .PARAMETER ID
        Specify the ID for an existing Win32 application to retrieve additional requirement rules from.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2026-06-03
        Updated:     2026-06-03

        Version history:
        1.0.0 - (2026-06-03) Function created
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the ID for an existing Win32 application to retrieve additional requirement rules from.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID
    )
    Begin {
        # Ensure required authentication header variable exists
        if (-not (Test-AuthenticationState)) {
            Write-Warning -Message "Authentication token was not found, use Connect-MSIntuneGraph before using this function"; break
        }

        # Set script variable for error action preference
        $ErrorActionPreference = "Stop"
    }
    Process {
        # Retrieve Win32 app by ID from parameter input
        Write-Verbose -Message "Querying for Win32 app using ID: $($ID)"
        $Win32App = Invoke-MSGraphOperation -Get -APIVersion "Beta" -Resource "deviceAppManagement/mobileApps/$($ID)"
        if ($null -ne $Win32App) {
            # Handle return value
            if ($null -ne $Win32App.requirementRules) {
                return $Win32App.requirementRules
            }
            else {
                Write-Verbose -Message "No additional requirement rules found for Win32 app with ID: $($ID)"
            }
        }
        else {
            Write-Warning -Message "Query for Win32 app returned an empty result, no apps matching the specified search criteria with ID '$($ID)' was found"
        }

        # Return empty array for consistency
        return @()
    }
}

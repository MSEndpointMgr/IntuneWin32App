function New-IntuneWin32AppSupersedence {
    <#
    .SYNOPSIS
        Create a new supersedence object to be used for the Add-IntuneWin32AppSupersedence function.

    .DESCRIPTION
        Create a new supersedence object to be used for the Add-IntuneWin32AppSupersedence function.

    .PARAMETER ID
        Specify the ID for an existing Win32 application.

    .PARAMETER SupersedenceType
        Specify the supersedence behavior, use Replace for uninstall and Update for when updating an app.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2021-04-01
        Updated:     2021-08-31

        Version history:
        1.0.0 - (2021-04-01) Function created
        1.0.1 - (2021-08-31) Updated to use new authentication header
        1.0.2 - (2026-10-12) Removed the token lifetime check that read ExpiresOn from the authentication header, which no longer carries that entry (see New-AuthenticationHeader, #182).
                             Like the other functions, token validity and renewal is handled by Invoke-MSGraphOperation using Test-AccessToken.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the ID for an existing Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID,
        
        [parameter(Mandatory = $true, HelpMessage = "Specify the supersedence behavior, use Replace for uninstall and Update for when updating an app.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Replace", "Update")]
        [string]$SupersedenceType
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
            $Win32AppID = $Win32App.id

            # Construct supersedence table
            $Supersedence = [ordered]@{
                "@odata.type" = "#microsoft.graph.mobileAppSupersedence"
                "supersedenceType" = $SupersedenceType.ToLower()
                "targetId" = $Win32AppID
            }

            # Handle return value
            return $Supersedence
        }
        else {
            Write-Warning -Message "Query for Win32 app returned an empty result, no apps matching the specified search criteria with ID '$($ID)' was found"
        }
    }
}
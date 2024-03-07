function Remove-IntuneWin32AppDependency {
<#
    .SYNOPSIS
        Remove all dependency configuration from an existing Win32 application.

    .DESCRIPTION
        Remove all dependency configuration from an existing Win32 application.

    .PARAMETER ID
        Specify the ID for an existing Win32 application where dependency configuration will be removed.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2021-08-31
        Updated:     2024-03-07

        Version history:
        1.0.0 - (2021-08-31) Function created
        1.0.1 - (2023-09-04) Updated with Test-AccessToken function. Updated to remove dependency configuration and not include supersedence configuration
        1.0.2 - (2024-01-05) Fixed issue reported in #123, where the relationships table was not created correctly due a typo when creating an empty array
        1.0.3 - (2024-03-07) Fixed a bug where the function would not handle empty supersedence object correctly
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the ID for an existing Win32 application where dependency configuration will be removed.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID
    )
    Begin {
        # Ensure required authentication header variable exists
        if ($Global:AuthenticationHeader -eq $null) {
            Write-Warning -Message "Authentication token was not found, use Connect-MSIntuneGraph before using this function"; break
        }
        else {
            if ((Test-AccessToken) -eq $false) {
                Write-Warning -Message "Existing token found but has expired, use Connect-MSIntuneGraph to request a new authentication token"; break
            }
        }

        # Set script variable for error action preference
        $ErrorActionPreference = "Stop"
    }
    Process {
        # Retrieve Win32 app by ID from parameter input
        Write-Verbose -Message "Querying for Win32 app using ID: $($ID)"
        $Win32App = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($ID)" -Method "GET"
        if ($Win32App -ne $null) {
            $Win32AppID = $Win32App.id

            # Check for existing supersedence relations for Win32 app, as these relationships should not be removed
            $Supersedence = Get-IntuneWin32AppSupersedence -ID $Win32AppID

            # Create relationships table to handle empty supersedence relations
            $Win32AppRelationshipsTable = [ordered]@{
                "relationships" = if ($Supersedence) { @($Supersedence) } else { , @() }
            }

            try {
                # Attempt to call Graph and remove dependency configuration for Win32 app
                Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32AppID)/updateRelationships" -Method "POST" -Body ($Win32AppRelationshipsTable | ConvertTo-Json) -ErrorAction Stop
            }
            catch [System.Exception] {
                Write-Warning -Message "An error occurred while removing dependency configuration for Win32 app: $($Win32AppID). Error message: $($_.Exception.Message)"
            }
        }
        else {
            Write-Warning -Message "Query for Win32 app returned an empty result, no apps matching the specified search criteria with ID '$($ID)' was found"
        }
    }
}
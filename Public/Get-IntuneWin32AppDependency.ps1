function Get-IntuneWin32AppDependency {
<#
    .SYNOPSIS
        Retrieve dependency configuration from an existing Win32 application.

    .DESCRIPTION
        Retrieve dependency configuration from an existing Win32 application.

    .PARAMETER ID
        Specify the ID for an existing Win32 application to retrieve dependency configuration.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2021-08-31
        Updated:     2023-09-04

        Version history:
        1.0.0 - (2021-08-31) Function created
        1.0.1 - (2023-09-04) Updated with Test-AccessToken function
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the ID for an existing Win32 application to retrieve dependency configuration.")]
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
            $Win32AppID = $Win32App.id

            try {
                # Attempt to call Graph and retrieve dependency configuration for Win32 app
                # Force arrays: a single result arrives as a scalar object, which has no .Count on Windows PowerShell 5.1
                $Win32AppRelationsResponse = @(Invoke-MSGraphOperation -Get -APIVersion "Beta" -Resource "deviceAppManagement/mobileApps/$($Win32AppID)/relationships" -ErrorAction Stop)

                # Handle return value
                if ($Win32AppRelationsResponse.Count -gt 0) {
                    # Filter for dependency relationships
                    $DependencyRelationships = @($Win32AppRelationsResponse | Where-Object { $_.'@odata.type' -eq "#microsoft.graph.mobileAppDependency" })
                    if ($DependencyRelationships.Count -gt 0) {
                        Write-Verbose -Message "Found $(@($DependencyRelationships).Count) dependency relationship(s)"
                        return $DependencyRelationships
                    }
                    else {
                        Write-Verbose -Message "No dependency relationships found for Win32 app: $($Win32AppID)"
                    }
                }
            }
            catch [System.Exception] {
                Write-Warning -Message "An error occurred while retrieving supersedence configuration for Win32 app: $($Win32AppID). Error message: $($_.Exception.Message)"
            }
        }
        else {
            Write-Verbose -Message "Query for Win32 app returned an empty result, no apps matching the specified search criteria with ID '$($ID)' was found"
        }
        
        # Return empty array for consistency
        return @()
    }
}
function Add-IntuneWin32AppDependency {
<#
    .SYNOPSIS
        Add dependency configuration to an existing Win32 application.

    .DESCRIPTION
        Add dependency configuration to an existing Win32 application.

    .PARAMETER ID
        Specify the ID for an existing Win32 application where the dependency will be configured.

    .PARAMETER Dependency
        Provide an array of a single or multiple OrderedDictionary objects created with New-IntuneWin32AppDependency function.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2021-08-31
        Updated:     2024-01-05

        Version history:
        1.0.0 - (2021-08-31) Function created
        1.0.1 - (2023-09-04) Fixed adding a dependency to not overwrite existing supersedence rules, reported in PR #105 (thank you pvorselaars). Updated with Test-AccessToken function
        1.0.2 - (2024-01-05) Fixed a object property construction issue when creating the relationships table #122
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the ID for an existing Win32 application where supersedence will be configured.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID,
        
        [parameter(Mandatory = $true, HelpMessage = "Provide an array of a single or multiple OrderedDictionary objects created with New-IntuneWin32AppDependency function.")]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.OrderedDictionary[]]$Dependency
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

        # Validate maximum number of dependency configuration tables
        if ($Dependency.Count -gt 100) {
            Write-Warning -Message "Maximum allowed number of dependency objects '100' detected, actual count passed as input: $($Dependency.Count)"; break
        }
    }
    Process {
        # Retrieve Win32 app by ID from parameter input
        Write-Verbose -Message "Querying for Win32 app using ID: $($ID)"
        $Win32App = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($ID)" -Method "GET"
        if ($Win32App -ne $null) {
            $Win32AppID = $Win32App.id

            # Check for existing supersedence relations for Win32 app, as these relationships need to be included in the update
            $Supersedence = Get-IntuneWin32AppSupersedence -ID $Win32AppID

            # Validate that Win32 app where dependency is configured, is not passed in $Dependency variable to prevent an app depending on itself
            if ($Win32AppID -notin $Dependency.targetId) {
                $Win32AppRelationshipsTable = [ordered]@{
                    "relationships" = @(if ($Supersedence) { @($Dependency; $Supersedence) } else { @($Dependency) })
                }

                try {
                    # Attempt to call Graph and configure dependency for Win32 app
                    Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32AppID)/updateRelationships" -Method "POST" -Body ($Win32AppRelationshipsTable | ConvertTo-Json) -ErrorAction Stop
                }
                catch [System.Exception] {
                    Write-Warning -Message "An error occurred while configuring dependency for Win32 app: $($Win32AppID). Error message: $($_.Exception.Message)"
                }
            }
            else {
                $DependencyItems = -join@($Dependency.targetId, ", ")
                Write-Warning -Message "A Win32 app cannot be used to dependend on itself, please specify a valid array or single object for dependency"
                Write-Warning -Message "Win32 app with ID '$($Win32AppID)' is set as parent for dependency configuration, and was also found in child items: $($DependencyItems)"
            }
        }
        else {
            Write-Warning -Message "Query for Win32 app returned an empty result, no apps matching the specified search criteria with ID '$($ID)' was found"
        }
    }
}
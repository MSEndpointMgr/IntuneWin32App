function Add-IntuneWin32AppRequirement {
    <#
    .SYNOPSIS
        Add additional requirement rules to an existing Win32 application.

    .DESCRIPTION
        Add additional requirement rules to an existing Win32 application.
        Existing additional requirement rules on the app are preserved and the new rules
        are appended to them. Use New-IntuneWin32AppRequirementRuleFile,
        New-IntuneWin32AppRequirementRuleRegistry or New-IntuneWin32AppRequirementRuleScript
        to construct the rule objects to pass to this function.

    .PARAMETER ID
        Specify the ID for an existing Win32 application where additional requirement rules will be added.

    .PARAMETER AdditionalRequirementRule
        Provide an array of a single or multiple OrderedDictionary objects created with
        New-IntuneWin32AppRequirementRuleFile, New-IntuneWin32AppRequirementRuleRegistry or
        New-IntuneWin32AppRequirementRuleScript functions.

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
        [parameter(Mandatory = $true, HelpMessage = "Specify the ID for an existing Win32 application where additional requirement rules will be added.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID,

        [parameter(Mandatory = $true, HelpMessage = "Provide an array of a single or multiple OrderedDictionary objects created with New-IntuneWin32AppRequirementRuleFile, New-IntuneWin32AppRequirementRuleRegistry or New-IntuneWin32AppRequirementRuleScript functions.")]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.OrderedDictionary[]]$AdditionalRequirementRule
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
        $Win32App = Invoke-MSGraphOperation -Get -APIVersion "Beta" -Resource "mobileApps/$($ID)"
        if ($Win32App -ne $null) {
            $Win32AppID = $Win32App.id

            # Retrieve existing additional requirement rules and merge with new ones to avoid overwriting
            $ExistingRequirementRules = Get-IntuneWin32AppRequirement -ID $Win32AppID
            $MergedRequirementRules = if ($ExistingRequirementRules) {
                @($ExistingRequirementRules) + @($AdditionalRequirementRule)
            }
            else {
                @($AdditionalRequirementRule)
            }

            # Construct request body for PATCH operation
            $Win32AppBody = @{
                "@odata.type"    = "#microsoft.graph.win32LobApp"
                requirementRules = $MergedRequirementRules
            }

            try {
                # Attempt to call Graph and add additional requirement rules to Win32 app
                Write-Verbose -Message "Attempting to add $($AdditionalRequirementRule.Count) additional requirement rule(s) to Win32 app with ID: $($Win32AppID)"
                $Win32AppResponse = Invoke-MSGraphOperation -Patch -APIVersion "Beta" -Resource "mobileApps/$($Win32AppID)" -Body ($Win32AppBody | ConvertTo-Json -Depth 10) -ContentType "application/json"
                Write-Verbose -Message "Successfully added additional requirement rule(s) to Win32 app with ID: $($Win32AppID)"
            }
            catch [System.Exception] {
                Write-Warning -Message "An error occurred while adding additional requirement rules to Win32 app: $($Win32AppID). Error message: $($_.Exception.Message)"
            }
        }
        else {
            Write-Warning -Message "Query for Win32 app returned an empty result, no apps matching the specified search criteria with ID '$($ID)' was found"
        }
    }
}

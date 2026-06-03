function Remove-IntuneWin32AppRequirement {
    <#
    .SYNOPSIS
        Remove additional requirement rules from an existing Win32 application.

    .DESCRIPTION
        Remove additional requirement rules from an existing Win32 application.
        Use the -All switch to remove all additional requirement rules, or filter by
        rule type using the -RuleType parameter to remove only rules of a specific type.

    .PARAMETER ID
        Specify the ID for an existing Win32 application where additional requirement rules will be removed.

    .PARAMETER All
        Remove all additional requirement rules from the Win32 application.

    .PARAMETER RuleType
        Remove only additional requirement rules of the specified type.
        Supported values are: File, Registry, Script.

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
        [parameter(Mandatory = $true, HelpMessage = "Specify the ID for an existing Win32 application where additional requirement rules will be removed.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID,

        [parameter(Mandatory = $true, ParameterSetName = "All", HelpMessage = "Remove all additional requirement rules from the Win32 application.")]
        [switch]$All,

        [parameter(Mandatory = $true, ParameterSetName = "RuleType", HelpMessage = "Remove only additional requirement rules of the specified type. Supported values are: File, Registry, Script.")]
        [ValidateSet("File", "Registry", "Script")]
        [ValidateNotNullOrEmpty()]
        [string]$RuleType
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

        # Build the odata.type filter string for the selected rule type
        $RuleTypeMap = @{
            "File"     = "#microsoft.graph.win32LobAppFileSystemRequirement"
            "Registry" = "#microsoft.graph.win32LobAppRegistryRequirement"
            "Script"   = "#microsoft.graph.win32LobAppPowerShellScriptRequirement"
        }
    }
    Process {
        # Retrieve Win32 app by ID from parameter input
        Write-Verbose -Message "Querying for Win32 app using ID: $($ID)"
        $Win32App = Invoke-MSGraphOperation -Get -APIVersion "Beta" -Resource "mobileApps/$($ID)"
        if ($Win32App -ne $null) {
            $Win32AppID = $Win32App.id

            # Retrieve existing additional requirement rules
            $ExistingRequirementRules = Get-IntuneWin32AppRequirement -ID $Win32AppID
            if ($ExistingRequirementRules -eq $null) {
                Write-Verbose -Message "No additional requirement rules found for Win32 app with ID: $($Win32AppID), nothing to remove"
                return
            }

            # Determine the filtered set of rules to keep
            if ($PSCmdlet.ParameterSetName -eq "All") {
                Write-Verbose -Message "Removing all additional requirement rules from Win32 app with ID: $($Win32AppID)"
                $RemainingRequirementRules = @()
            }
            else {
                $ODataType = $RuleTypeMap[$RuleType]
                Write-Verbose -Message "Removing additional requirement rules of type '$($ODataType)' from Win32 app with ID: $($Win32AppID)"
                $RemainingRequirementRules = @($ExistingRequirementRules | Where-Object { $_.'@odata.type' -ne $ODataType })
            }

            # Construct request body for PATCH operation
            $Win32AppBody = @{
                "@odata.type"    = "#microsoft.graph.win32LobApp"
                requirementRules = $RemainingRequirementRules
            }

            try {
                # Attempt to call Graph and update requirement rules on Win32 app
                $Win32AppResponse = Invoke-MSGraphOperation -Patch -APIVersion "Beta" -Resource "mobileApps/$($Win32AppID)" -Body ($Win32AppBody | ConvertTo-Json -Depth 10) -ContentType "application/json"
                Write-Verbose -Message "Successfully removed additional requirement rule(s) from Win32 app with ID: $($Win32AppID)"
            }
            catch [System.Exception] {
                Write-Warning -Message "An error occurred while removing additional requirement rules from Win32 app: $($Win32AppID). Error message: $($_.Exception.Message)"
            }
        }
        else {
            Write-Warning -Message "Query for Win32 app returned an empty result, no apps matching the specified search criteria with ID '$($ID)' was found"
        }
    }
}

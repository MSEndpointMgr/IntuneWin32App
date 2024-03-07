function Add-IntuneWin32AppSupersedence {
    <#
    .SYNOPSIS
        Add supersedence configuration to an existing Win32 application.

    .DESCRIPTION
        Add supersedence configuration to an existing Win32 application.

    .PARAMETER ID
        Specify the ID for an existing Win32 application where supersedence will be configured.

    .PARAMETER Supersedence
        Provide an array of a single or multiple OrderedDictionary objects created with New-IntuneWin32AppSupersedence function.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2021-04-01
        Updated:     2024-01-05

        Version history:
        1.0.0 - (2021-04-01) Function created
        1.0.1 - (2021-08-31) Updated to use new authentication header
        1.0.1 - (2023-09-04) Fixed adding a dependency to not overwrite existing supersedence rules, reported in PR #105 (thank you pvorselaars). Updated with Test-AccessToken function
        1.0.2 - (2024-01-05) Fixed a object property construction issue when creating the relationships table #122
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the ID for an existing Win32 application where supersedence will be configured.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID,
        
        [parameter(Mandatory = $true, HelpMessage = "Provide an array of a single or multiple OrderedDictionary objects created with New-IntuneWin32AppSupersedence function.")]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.OrderedDictionary[]]$Supersedence
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

        # Validate maximum number of supersedence configuration tables
        if ($Supersedence.Count -gt 10) {
            Write-Warning -Message "Maximum allowed number of supersedence objects '10' detected, actual count passed as input: $($Supersedence.Count)"; break
        }
    }
    Process {
        # Retrieve Win32 app by ID from parameter input
        Write-Verbose -Message "Querying for Win32 app using ID: $($ID)"
        $Win32App = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($ID)" -Method "GET"
        if ($Win32App -ne $null) {
            $Win32AppID = $Win32App.id

            # Check for existing dependency relations for Win32 app, as these relationships need to be included in the update
            $Dependencies = Get-IntuneWin32AppDependency -ID $Win32AppID

            # Validate that the target Win32 app where supersedence is to be configured, is not passed in $Supersedence variable to prevent target app superseding itself
            if ($Win32AppID -notin $Supersedence.targetId) {
                $Win32AppRelationshipsTable = [ordered]@{
                    "relationships" = @(if ($Dependencies) { @($Supersedence; $Dependencies) } else { @($Supersedence) })
                }

                try {
                    # Attempt to call Graph and configure supersedence for Win32 app
                    Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32AppID)/updateRelationships" -Method "POST" -Body ($Win32AppRelationshipsTable | ConvertTo-Json) -ErrorAction Stop
                }
                catch [System.Exception] {
                    Write-Warning -Message "An error occurred while configuring supersedence for Win32 app: $($Win32AppID). Error message: $($_.Exception.Message)"
                }
            }
            else {
                $SupersedenceItems = -join@($Supersedence.targetId, ", ")
                Write-Warning -Message "A Win32 app cannot be used to supersede itself, please specify a valid array or single object for supersedence"
                Write-Warning -Message "Win32 app with ID '$($Win32AppID)' is set as parent for supersedence configuration, and was also found in child items: $($SupersedenceItems)"
            }
        }
        else {
            Write-Warning -Message "Query for Win32 app returned an empty result, no apps matching the specified search criteria with ID '$($ID)' was found"
        }
    }
}
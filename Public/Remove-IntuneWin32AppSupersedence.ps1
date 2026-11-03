function Remove-IntuneWin32AppSupersedence {
    <#
    .SYNOPSIS
        Remove all or specific supersedence configuration from an existing Win32 application.

    .DESCRIPTION
        Remove all or specific supersedence configuration from an existing Win32 application.

    .PARAMETER ID
        Specify the ID for an existing Win32 application where supersedence configuration will be removed.

    .PARAMETER SupersededID
        Specify the ID of one or more superseded Win32 applications to remove from the supersedence configuration. When not specified, all supersedence configuration is removed.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2021-04-02
        Updated:     2024-03-07

        Version history:
        1.0.0 - (2021-04-02) Function created
        1.0.1 - (2021-08-31) Updated to use new authentication header
        1.0.2 - (2023-09-04) Updated with Test-AccessToken function. Updated to remove supersedence configuration and not include dependency configuration
        1.0.3 - (2024-01-05) Fixed issue reported in #123, where the relationships table was not created correctly due a typo when creating an empty array
        1.0.4 - (2024-03-07) Fixed a bug where the function would not handle empty dependencies correctly
        1.0.5 - (2026-11-03) Added SupersededID parameter to remove individual supersedence relationships (#204)
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the ID for an existing Win32 application where supersedence configuration will be removed.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID,

        [parameter(Mandatory = $false, HelpMessage = "Specify the ID of one or more superseded Win32 applications to remove from the supersedence configuration.")]
        [ValidateNotNullOrEmpty()]
        [string[]]$SupersededID
    )
    Begin {
        # Ensure required authentication header variable exists
        if (-not (Test-AuthenticationState)) {
            throw "Authentication token was not found, use Connect-MSIntuneGraph before using this function"
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

            # Check for existing dependency relations for Win32 app, as these relationships should not be removed
            $Dependencies = Get-IntuneWin32AppDependency -ID $Win32AppID

            # Keep supersedence relationships that are not specified for removal when SupersededID parameter is passed on command line
            $Relationships = @($Dependencies | Where-Object { $null -ne $_ })
            if ($PSBoundParameters["SupersededID"]) {
                $ExistingSupersedence = @(Get-IntuneWin32AppSupersedence -ID $Win32AppID | Where-Object { ($null -ne $_) -and ($_.targetType -ne "parent") })
                foreach ($SupersededItem in $SupersededID) {
                    if ($SupersededItem -notin $ExistingSupersedence.targetId) {
                        Write-Warning -Message "Win32 app with ID '$($SupersededItem)' is not superseded by Win32 app with ID: $($Win32AppID)"
                    }
                }
                foreach ($SupersedenceItem in ($ExistingSupersedence | Where-Object { $_.targetId -notin $SupersededID })) {
                    $Relationships += [ordered]@{
                        "@odata.type" = "#microsoft.graph.mobileAppSupersedence"
                        "supersedenceType" = $SupersedenceItem.supersedenceType
                        "targetId" = $SupersedenceItem.targetId
                    }
                }
            }

            # Create relationships body - handle empty array case
            if ($Relationships.Count -gt 0) {
                $Win32AppRelationshipsTable = @{
                    "relationships" = $Relationships
                }
                $Body = $Win32AppRelationshipsTable | ConvertTo-Json -Depth 10 -Compress
            }
            else {
                # Manually construct JSON with empty array since ConvertTo-Json may convert @() to null
                $Body = '{"relationships":[]}'
            }

            Write-Verbose -Message "Request body: $Body"

            # Attempt to call Graph and remove supersedence configuration for Win32 app
            if ($PSCmdlet.ShouldProcess("deviceAppManagement/mobileApps/$($Win32AppID)/updateRelationships", "POST")) {
                Invoke-MSGraphOperation -Post -APIVersion "Beta" -Resource "deviceAppManagement/mobileApps/$($Win32AppID)/updateRelationships" -Body $Body
            }
        }
        else {
            Write-Verbose -Message "Query for Win32 app returned an empty result, no apps matching the specified search criteria with ID '$($ID)' was found"
        }
    }
}
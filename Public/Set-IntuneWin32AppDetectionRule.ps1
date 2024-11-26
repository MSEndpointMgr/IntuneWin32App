function Set-IntuneWin32AppDetectionRule {
    <#
    .SYNOPSIS
        Update an existing Win32 application rule set in Intune.

    .DESCRIPTION
        Update an existing Win32 application rule set in Intune, for instance update with a new detection rule, change the description or app version information.

    .PARAMETER ID
        Specify the ID of the targeted Win32 application where changes will be applied.

    .PARAMETER DisplayName
        Specify a new display name for the Win32 application.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2024-11-26
        Updated:     2024-11-26

        Version history:
        1.0.0 - (2024-11-26) Function created
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the ID of the targeted Win32 application where changes will be applied.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID,

        [parameter(Mandatory = $true, HelpMessage = "Provide an array of a single or multiple OrderedDictionary objects as detection rules that will be used for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.OrderedDictionary[]]$DetectionRule
    )
    Begin {
        # Ensure required authentication header variable exists
        if ($null -eq $Global:AuthenticationHeader) {
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
        if ($null -ne $Win32App) {
            $Win32AppID = $Win32App.id

            # Construct required part of request body for PATCH operation
            $Win32AppBody = @{
                "@odata.type" = "#microsoft.graph.win32LobApp"
            }

            # Validate that correct detection rules have been passed on command line, only 1 PowerShell script based detection rule is allowed
            if (($DetectionRule.'@odata.type' -contains "#microsoft.graph.win32LobAppPowerShellScriptDetection") -and (@($DetectionRules).'@odata.type'.Count -gt 1)) {
                Write-Warning -Message "Multiple PowerShell Script detection rules were detected, this is not a supported configuration"; break
            }
            
            # Add detection rules to Win32 app body object
            Write-Verbose -Message "Detection rule objects passed validation checks, attempting to add to existing Win32 app body"
            $Win32AppBody.Add("detectionRules", $DetectionRule)

            try {
                # Attempt to call Graph and update Win32 app
                $Win32AppResponse = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32AppID)" -Method "PATCH" -Body ($Win32AppBody | ConvertTo-Json) -ContentType "application/json" -ErrorAction "Stop"
                Write-Verbose -Message "Successfully updated Win32 app object with ID: $($Win32AppID)"
            }
            catch [System.Exception] {
                Write-Warning -Message "An error occurred while update Win32 app object. Error message: $($_.Exception.Message)"
            }
        }
        else {
            Write-Warning -Message "Query for Win32 app returned an empty result, no apps matching the specified search criteria with ID '$($ID)' was found"
        }
    }
    
}
function Set-IntuneWin32App {
    <#
    .SYNOPSIS
        Update an existing Win32 application object in Intune.

    .DESCRIPTION
        Update an existing Win32 application object in Intune, for instance update with a new display name, change the description or app version information.

    .PARAMETER ID
        Specify the ID of the targeted Win32 application where changes will be applied.

    .PARAMETER DisplayName
        Specify a new display name for the Win32 application.

    .PARAMETER Description
        Specify a new description for the Win32 application.

    .PARAMETER Publisher
        Specify a new publisher name for the Win32 application.

    .PARAMETER AppVersion
        Specify a new app version for the Win32 application.

    .PARAMETER Developer
        Specify a new developer name for the Win32 application.

    .PARAMETER Owner
        Specify a new owner property for the Win32 application.

    .PARAMETER Notes
        Specify a new notes property for the Win32 application.

    .PARAMETER InformationURL
        Specify a new information URL for the Win32 application.

    .PARAMETER PrivacyURL
        Specify a new privacy URL for the Win32 application.

    .PARAMETER CompanyPortalFeaturedApp
        Specify whether to have the Win32 application featured in Company Portal or not.

    .PARAMETER DetectionRule
        Provide an array of a single or multiple OrderedDictionary objects as detection rules to override the current detection rules for the Win32 application.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2023-01-25
        Updated:     2023-09-04

        Version history:
        1.0.0 - (2023-01-25) Function created
        1.0.1 - (2023-03-17) Added AllowAvailableUninstall parameter switch.
        1.0.2 - (2023-09-04) Updated with Test-AccessToken function
        1.0.3 - (2025-10-20) Added additional parameters and improved error handling
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the ID of the targeted Win32 application where changes will be applied.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID,

        [parameter(Mandatory = $false, HelpMessage = "Specify a new display name for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [parameter(Mandatory = $false, HelpMessage = "Specify a new description for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$Description,

        [parameter(Mandatory = $false, HelpMessage = "Specify a new publisher name for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$Publisher,

        [parameter(Mandatory = $false, HelpMessage = "Specify a new app version for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$AppVersion,

                [parameter(Mandatory = $false, HelpMessage = "Specify the name of either a single or an array of category names for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string[]]$CategoryName,
        
                [parameter(Mandatory = $false, HelpMessage = "Specify whether to have the Win32 application featured in Company Portal or not.")]
        [bool]$CompanyPortalFeaturedApp,

        [parameter(Mandatory = $false, HelpMessage = "Specify a new information URL for the Win32 application.")]
        [ValidatePattern("(http[s]?|[s]?ftp[s]?)(:\/\/)([^\s,]+)")]
        [string]$InformationURL,

        [parameter(Mandatory = $false, HelpMessage = "Specify a new privacy URL for the Win32 application.")]
        [ValidatePattern("(http[s]?|[s]?ftp[s]?)(:\/\/)([^\s,]+)")]
        [string]$PrivacyURL,

        
        [parameter(Mandatory = $false, HelpMessage = "Specify a new developer name for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$Developer,

        [parameter(Mandatory = $false, HelpMessage = "Specify a new owner property for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$Owner,

        [parameter(Mandatory = $false, HelpMessage = "Specify a new notes property for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$Notes,

        [parameter(Mandatory = $false, HelpMessage = "Provide a Base64 encoded string of the PNG/JPG/JPEG file.")]
        [ValidateNotNullOrEmpty()]
        [string]$Icon,

        [parameter(Mandatory = $false, HelpMessage = "Specify the install command line for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$InstallCommandLine,

        [parameter(Mandatory = $false, HelpMessage = "Specify the uninstall command line for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$UninstallCommandLine,

        [parameter(Mandatory = $false, HelpMessage = "Specify the maximum installation time in minutes for the Win32 application (default is 60 minutes).")]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 1440)]
        [int]$MaximumInstallationTimeInMinutes = 60,

        [parameter(Mandatory = $false, HelpMessage = "Specify whether to allow the Win32 application to be uninstalled from the Company Portal app when assigned as available.")]
        [bool]$AllowAvailableUninstall,

        [parameter(Mandatory = $false, HelpMessage = "Specify the restart behavior for the Win32 application. Supported values are: allow, basedOnReturnCode, suppress or force.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("allow", "basedOnReturnCode", "suppress", "force")]
        [string]$RestartBehavior,

        [parameter(Mandatory = $false, HelpMessage = "Provide an array of a single or multiple hash-tables for the Win32 application with return code information.")]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable[]]$ReturnCode,

        [parameter(Mandatory = $false, HelpMessage = "Provide an OrderedDictionary object as requirement rule that will be used for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.OrderedDictionary]$RequirementRule,

        [parameter(Mandatory = $false, HelpMessage = "Provide an array of OrderedDictionary objects as additional requirement rule, e.g. for file, registry or script rules, that will be used for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.OrderedDictionary[]]$AdditionalRequirementRule,

        [parameter(Mandatory = $false, HelpMessage = "Provide an array of a single or multiple OrderedDictionary objects as detection rules to override the current detection rules for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.OrderedDictionary[]]$DetectionRule
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

            # Construct required part of request body for PATCH operation
            $Win32AppBody = @{
                "@odata.type" = "#microsoft.graph.win32LobApp"
            }

            # Dynamically extend request body depending on what parameters are passed on the command line
            if ($PSBoundParameters["DisplayName"]) {
                $Win32AppBody.Add("displayName", $DisplayName)
            }
            if ($PSBoundParameters["Description"]) {
                $Win32AppBody.Add("description", $Description)
            }
            if ($PSBoundParameters["Publisher"]) {
                $Win32AppBody.Add("publisher", $Publisher)
            }
            if ($PSBoundParameters["AppVersion"]) {
                $Win32AppBody.Add("displayVersion", $AppVersion)
            }
            if ($PSBoundParameters["Developer"]) {
                $Win32AppBody.Add("developer", $Developer)
            }
            if ($PSBoundParameters["Owner"]) {
                $Win32AppBody.Add("owner", $Owner)
            }
            if ($PSBoundParameters["Notes"]) {
                $Win32AppBody.Add("notes", $Notes)
            }
            if ($PSBoundParameters["InformationURL"]) {
                $Win32AppBody.Add("informationUrl", $InformationURL)
            }
            if ($PSBoundParameters["PrivacyURL"]) {
                $Win32AppBody.Add("privacyUrl", $PrivacyURL)
            }
            if ($PSBoundParameters["CompanyPortalFeaturedApp"]) {
                $Win32AppBody.Add("isFeatured", $CompanyPortalFeaturedApp)
            }
            if ($PSBoundParameters["CategoryName"]) {
                $CategoryList = New-Object -TypeName "System.Collections.ArrayList"
                foreach ($CategoryNameItem in $CategoryName) {
                    # Ensure category exist by given name from parameter input
                    Write-Verbose -Message "Querying for specified Category: $($CategoryNameItem)"
                    $Category = (Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileAppCategories?`$filter=displayName eq '$([System.Web.HttpUtility]::UrlEncode($CategoryNameItem))'" -Method "GET" -ErrorAction "Stop").value
                    if ($Category -ne $null) {
                        $PSObject = [PSCustomObject]@{
                            id          = $Category.id
                            displayName = $Category.displayName
                        }
                        $CategoryList.Add($PSObject) | Out-Null
                    }
                    else {
                        Write-Warning -Message "Could not find category with name '$($CategoryNameItem)' or provided name resulted in multiple matches which is not supported"
                    }
                }

                if ($CategoryList.Count -ge 1) {
                    $Win32AppBody.Add("CategoryList", $CategoryList)
                }
            }
            if ($PSBoundParameters["InstallCommandLine"]) {
                $Win32AppBody.Add("installCommandLine", $InstallCommandLine)
            }
            if ($PSBoundParameters["UninstallCommandLine"]) {
                $Win32AppBody.Add("uninstallCommandLine", $UninstallCommandLine)
            }
            if ($PSBoundParameters["RestartBehavior"]) {
                $Win32AppBody.Add("restartBehavior", $RestartBehavior)
            }
            if ($PSBoundParameters["MaximumInstallationTimeInMinutes"]) {
                $Win32AppBody.Add("maximumRunTimeInMinutes", $MaximumInstallationTimeInMinutes)
            }
            if ($PSBoundParameters["RequirementRule"]) {
                $Win32AppBody.Add("requirementRule", @($RequirementRule))
            }
            if ($PSBoundParameters["AdditionalRequirementRule"]) {
                if ($Win32AppBody.ContainsKey("requirementRules")) {
                    $Win32AppBody["requirementRules"] += $AdditionalRequirementRule
                }
                else {
                    $Win32AppBody.Add("requirementRules", $AdditionalRequirementRule)
                }
            }
            if ($PSBoundParameters["ReturnCode"]) {
                # Retrieve the default return codes for a Win32 app
                Write-Verbose -Message "Retrieving default set of return codes for Win32 app body construction"
                $DefaultReturnCodes = Get-IntuneWin32AppDefaultReturnCode

                # Add custom return codes from parameter input to default set of objects
                Write-Verbose -Message "Additional return codes where passed as command line input, adding to array of default return codes"
                foreach ($ReturnCodeItem in $ReturnCode) {
                    $DefaultReturnCodes += $ReturnCodeItem
                }

                # Add return codes to Win32 app body object
                Write-Verbose -Message "Adding array of return codes to Win32 app body construction"
                $Win32AppBody.Add("returnCodes", $DefaultReturnCodes)
            }
            if ($PSBoundParameters["Icon"]) {
                $Win32AppBody.Add("largeIcon", @{
                        "@odata.type" = "#microsoft.graph.mimeContent"
                        "type"        = "image/png"
                        "value"       = $Icon
                    })
            }
            if ($PSBoundParameters["AllowAvailableUninstall"]) {
                $Win32AppBody.Add("allowAvailableUninstall", $AllowAvailableUninstall)
            }
            if ($PSBoundParameters["DetectionRule"]) {
                # Validate that correct detection rules have been passed on command line, only 1 PowerShell script based detection rule is allowed
                if (($DetectionRule.'@odata.type' -contains "#microsoft.graph.win32LobAppPowerShellScriptDetection") -and (@($DetectionRule).'@odata.type'.Count -gt 1)) {
                    Write-Warning -Message "Multiple PowerShell Script detection rules were detected, this is not a supported configuration"; break
                }
               
                # Add detection rules to Win32 app body object
                Write-Verbose -Message "Detection rule objects passed validation checks, attempting to add to existing Win32 app body"
                $Win32AppBody.Add("detectionRules", $DetectionRule)
            }

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
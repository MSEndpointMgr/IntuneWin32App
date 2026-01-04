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

    .PARAMETER AllowAvailableUninstall
        Specify whether to allow the Win32 application to be uninstalled from the Company Portal app when assigned as available.

    .PARAMETER DetectionRule
        Provide an array of a single or multiple OrderedDictionary objects as detection rules that will be used for the Win32 application.

    .PARAMETER CategoryName
        Specify the name of either a single or an array of category names for the Win32 application.

    .PARAMETER Icon
        Provide a Base64 encoded string of the PNG/JPG/JPEG file.

    .PARAMETER InstallCommandLine
        Specify the install command line for the Win32 application.

    .PARAMETER UninstallCommandLine
        Specify the uninstall command line for the Win32 application.

    .PARAMETER RestartBehavior
        Specify the restart behavior for the Win32 application. Supported values are: allow, basedOnReturnCode, suppress or force.

    .PARAMETER MaximumInstallationTimeInMinutes
        Specify the maximum installation time in minutes for the Win32 application (default is 60 minutes, range: 1-1440).

    .PARAMETER RequirementRule
        Provide an OrderedDictionary object as requirement rule that will be used for the Win32 application.

    .PARAMETER AdditionalRequirementRule
        Provide an array of OrderedDictionary objects as additional requirement rule, e.g. for file, registry or script rules, that will be used for the Win32 application.

    .PARAMETER ReturnCode
        Provide an array of a single or multiple hash-tables for the Win32 application with return code information.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2023-01-25
        Updated:     2026-01-01

        Version history:
        1.0.0 - (2023-01-25) Function created
        1.0.1 - (2023-03-17) Added AllowAvailableUninstall parameter switch.
        1.0.2 - (2023-09-04) Updated with Test-AccessToken function
        1.0.3 - (2026-01-01) Added DetectionRule parameter with comprehensive validation (PR #197)
        1.0.4 - (2026-01-01) Added CategoryName, Icon, Install/Uninstall commands, RestartBehavior, MaximumInstallationTimeInMinutes, RequirementRule, AdditionalRequirementRule, and ReturnCode parameters with validation (PR #202)
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

        [parameter(Mandatory = $false, HelpMessage = "Specify a new developer name for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$Developer,

        [parameter(Mandatory = $false, HelpMessage = "Specify a new owner property for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$Owner,

        [parameter(Mandatory = $false, HelpMessage = "Specify a new notes property for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$Notes,

        [parameter(Mandatory = $false, HelpMessage = "Specify a new information URL for the Win32 application.")]
        [ValidatePattern("(http[s]?|[s]?ftp[s]?)(:\/\/)([^\s,]+)")]
        [string]$InformationURL,

        [parameter(Mandatory = $false, HelpMessage = "Specify a new privacy URL for the Win32 application.")]
        [ValidatePattern("(http[s]?|[s]?ftp[s]?)(:\/\/)([^\s,]+)")]
        [string]$PrivacyURL,

        [parameter(Mandatory = $false, HelpMessage = "Specify whether to have the Win32 application featured in Company Portal or not.")]
        [bool]$CompanyPortalFeaturedApp,

        [parameter(Mandatory = $false, HelpMessage = "Specify whether to allow the Win32 application to be uninstalled from the Company Portal app when assigned as available.")]
        [bool]$AllowAvailableUninstall,

        [parameter(Mandatory = $false, HelpMessage = "Provide an array of a single or multiple OrderedDictionary objects as detection rules that will be used for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.OrderedDictionary[]]$DetectionRule,

        [parameter(Mandatory = $false, HelpMessage = "Specify the name of either a single or an array of category names for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string[]]$CategoryName,

        [parameter(Mandatory = $false, HelpMessage = "Provide a Base64 encoded string of the PNG/JPG/JPEG file.")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            # Validate Base64 string format
            try {
                [Convert]::FromBase64String($_) | Out-Null
                $true
            }
            catch {
                throw "Icon must be a valid Base64 encoded string"
            }
        })]
        [string]$Icon,

        [parameter(Mandatory = $false, HelpMessage = "Specify the install command line for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$InstallCommandLine,

        [parameter(Mandatory = $false, HelpMessage = "Specify the uninstall command line for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$UninstallCommandLine,

        [parameter(Mandatory = $false, HelpMessage = "Specify the restart behavior for the Win32 application. Supported values are: allow, basedOnReturnCode, suppress or force.")]
        [ValidateSet("allow", "basedOnReturnCode", "suppress", "force")]
        [string]$RestartBehavior,

        [parameter(Mandatory = $false, HelpMessage = "Specify the maximum installation time in minutes for the Win32 application (default is 60 minutes, range: 1-1440).")]
        [ValidateRange(1, 1440)]
        [int]$MaximumInstallationTimeInMinutes,

        [parameter(Mandatory = $false, HelpMessage = "Provide an OrderedDictionary object as requirement rule that will be used for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.OrderedDictionary]$RequirementRule,

        [parameter(Mandatory = $false, HelpMessage = "Provide an array of OrderedDictionary objects as additional requirement rule, e.g. for file, registry or script rules, that will be used for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.OrderedDictionary[]]$AdditionalRequirementRule,

        [parameter(Mandatory = $false, HelpMessage = "Provide an array of a single or multiple hash-tables for the Win32 application with return code information.")]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable[]]$ReturnCode
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
        $Win32App = Invoke-MSGraphOperation -Get -APIVersion "Beta" -Resource "deviceAppManagement/mobileApps/$($ID)"
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
                $Win32AppBody.Add("privacyInformationUrl", $PrivacyURL)
            }
            if ($PSBoundParameters["CompanyPortalFeaturedApp"]) {
                $Win32AppBody.Add("isFeatured", $CompanyPortalFeaturedApp)
            }
            if ($PSBoundParameters["AllowAvailableUninstall"]) {
                $Win32AppBody.Add("allowAvailableUninstall", $AllowAvailableUninstall)
            }
            if ($PSBoundParameters["CategoryName"]) {
                # Process category names and lookup their IDs
                Write-Verbose -Message "Processing category names"
                $CategoryList = New-Object -TypeName "System.Collections.ArrayList"
                
                foreach ($CategoryNameItem in $CategoryName) {
                    Write-Verbose -Message "Querying for category: $($CategoryNameItem)"
                    try {
                        $Category = Invoke-MSGraphOperation -Get -APIVersion "Beta" -Resource "deviceAppManagement/mobileAppCategories?`$filter=displayName eq '$([System.Web.HttpUtility]::UrlEncode($CategoryNameItem))'" -ErrorAction "Stop"
                        
                        if ($Category -ne $null) {
                            if ($Category.Count -eq 1) {
                                $PSObject = [PSCustomObject]@{
                                    "@odata.type" = "#microsoft.graph.mobileAppCategory"
                                    id = $Category.id
                                    displayName = $Category.displayName
                                }
                                $CategoryList.Add($PSObject) | Out-Null
                                Write-Verbose -Message "Found category '$($Category.displayName)' with ID: $($Category.id)"
                            }
                            else {
                                Write-Warning -Message "Multiple categories found with name '$($CategoryNameItem)', skipping"
                            }
                        }
                        else {
                            Write-Warning -Message "Could not find category with name '$($CategoryNameItem)'"
                        }
                    }
                    catch {
                        Write-Warning -Message "Error querying category '$($CategoryNameItem)': $($_.Exception.Message)"
                    }
                }
                
                if ($CategoryList.Count -ge 1) {
                    Write-Verbose -Message "Adding $($CategoryList.Count) categories to Win32 app body"
                    $Win32AppBody.Add("categories", $CategoryList)
                }
            }
            if ($PSBoundParameters["Icon"]) {
                Write-Verbose -Message "Adding icon to Win32 app body"
                $Win32AppBody.Add("largeIcon", @{
                    "@odata.type" = "#microsoft.graph.mimeContent"
                    "type" = "image/png"
                    "value" = $Icon
                })
            }
            if ($PSBoundParameters["InstallCommandLine"]) {
                $Win32AppBody.Add("installCommandLine", $InstallCommandLine)
            }
            if ($PSBoundParameters["UninstallCommandLine"]) {
                $Win32AppBody.Add("uninstallCommandLine", $UninstallCommandLine)
            }
            if ($PSBoundParameters["RestartBehavior"] -or $PSBoundParameters["MaximumInstallationTimeInMinutes"]) {
                # Build installExperience object
                $InstallExperience = @{}
                if ($PSBoundParameters["RestartBehavior"]) {
                    $InstallExperience.Add("deviceRestartBehavior", $RestartBehavior)
                }
                if ($PSBoundParameters["MaximumInstallationTimeInMinutes"]) {
                    $InstallExperience.Add("maxRunTimeInMinutes", $MaximumInstallationTimeInMinutes)
                }
                $Win32AppBody.Add("installExperience", $InstallExperience)
            }
            if ($PSBoundParameters["RequirementRule"]) {
                Write-Verbose -Message "Validating requirement rule"
                
                # Validate requirement rule is an OrderedDictionary
                if ($RequirementRule -isnot [System.Collections.Specialized.OrderedDictionary]) {
                    Write-Warning -Message "RequirementRule must be of type OrderedDictionary. Use New-IntuneWin32AppRequirementRule function to create requirement rules."
                    break
                }
                
                # Validate @odata.type property exists
                if (-not $RequirementRule.Contains("@odata.type")) {
                    Write-Warning -Message "RequirementRule is missing required '@odata.type' property."
                    break
                }
                
                Write-Verbose -Message "Adding requirement rule to Win32 app body"
                
                # If there's already a minimumSupportedOperatingSystem in the body, preserve it
                if (-not $Win32AppBody.ContainsKey("minimumSupportedOperatingSystem")) {
                    # Extract OS requirement from rule if present
                    if ($RequirementRule.ContainsKey("minimumSupportedOperatingSystem")) {
                        $Win32AppBody.Add("minimumSupportedOperatingSystem", $RequirementRule["minimumSupportedOperatingSystem"])
                    }
                }
                
                # Add additional requirement properties
                if ($RequirementRule.ContainsKey("minimumFreeDiskSpaceInMB") -and $RequirementRule["minimumFreeDiskSpaceInMB"] -ne $null) {
                    $Win32AppBody.Add("minimumFreeDiskSpaceInMB", $RequirementRule["minimumFreeDiskSpaceInMB"])
                }
                if ($RequirementRule.ContainsKey("minimumMemoryInMB") -and $RequirementRule["minimumMemoryInMB"] -ne $null) {
                    $Win32AppBody.Add("minimumMemoryInMB", $RequirementRule["minimumMemoryInMB"])
                }
                if ($RequirementRule.ContainsKey("minimumNumberOfProcessors") -and $RequirementRule["minimumNumberOfProcessors"] -ne $null) {
                    $Win32AppBody.Add("minimumNumberOfProcessors", $RequirementRule["minimumNumberOfProcessors"])
                }
                if ($RequirementRule.ContainsKey("minimumCpuSpeedInMHz") -and $RequirementRule["minimumCpuSpeedInMHz"] -ne $null) {
                    $Win32AppBody.Add("minimumCpuSpeedInMHz", $RequirementRule["minimumCpuSpeedInMHz"])
                }
            }
            if ($PSBoundParameters["AdditionalRequirementRule"]) {
                Write-Verbose -Message "Processing additional requirement rules"
                
                # Validate each additional requirement rule
                foreach ($Rule in $AdditionalRequirementRule) {
                    if ($Rule -isnot [System.Collections.Specialized.OrderedDictionary]) {
                        Write-Warning -Message "AdditionalRequirementRule must contain OrderedDictionary objects. Use New-IntuneWin32AppRequirementRule* functions."
                        break
                    }
                    
                    if (-not $Rule.Contains("@odata.type")) {
                        Write-Warning -Message "AdditionalRequirementRule is missing required '@odata.type' property."
                        break
                    }
                }
                
                Write-Verbose -Message "Adding $($AdditionalRequirementRule.Count) additional requirement rules to Win32 app body"
                $Win32AppBody.Add("requirementRules", $AdditionalRequirementRule)
            }
            if ($PSBoundParameters["ReturnCode"]) {
                Write-Verbose -Message "Processing return codes"
                
                # Retrieve default return codes
                $DefaultReturnCodes = Get-IntuneWin32AppDefaultReturnCode
                
                # Validate and add custom return codes
                foreach ($ReturnCodeItem in $ReturnCode) {
                    # Validate return code structure
                    if (-not $ReturnCodeItem.ContainsKey("returnCode")) {
                        Write-Warning -Message "ReturnCode object missing required 'returnCode' property"
                        break
                    }
                    if (-not $ReturnCodeItem.ContainsKey("type")) {
                        Write-Warning -Message "ReturnCode object missing required 'type' property"
                        break
                    }
                    
                    # Validate return code type
                    $ValidReturnCodeTypes = @("failed", "success", "softReboot", "hardReboot", "retry")
                    if ($ReturnCodeItem["type"] -notin $ValidReturnCodeTypes) {
                        Write-Warning -Message "Invalid return code type: $($ReturnCodeItem['type']). Valid types are: $($ValidReturnCodeTypes -join ', ')"
                        break
                    }
                    
                    $DefaultReturnCodes += $ReturnCodeItem
                }
                
                Write-Verbose -Message "Adding $($DefaultReturnCodes.Count) return codes to Win32 app body"
                $Win32AppBody.Add("returnCodes", $DefaultReturnCodes)
            }
            if ($PSBoundParameters["DetectionRule"]) {
                # Validate detection rule objects
                Write-Verbose -Message "Validating detection rule objects"
                
                # Define valid detection rule types
                $ValidDetectionTypes = @(
                    "#microsoft.graph.win32LobAppFileSystemDetection",
                    "#microsoft.graph.win32LobAppRegistryDetection",
                    "#microsoft.graph.win32LobAppProductCodeDetection",
                    "#microsoft.graph.win32LobAppPowerShellScriptDetection"
                )
                
                # Validate each detection rule
                foreach ($Rule in $DetectionRule) {
                    # Check if rule is an OrderedDictionary
                    if ($Rule -isnot [System.Collections.Specialized.OrderedDictionary]) {
                        Write-Warning -Message "Detection rule must be of type OrderedDictionary. Use New-IntuneWin32AppDetectionRule* functions to create detection rules."
                        break
                    }
                    
                    # Check if rule has @odata.type property
                    if (-not $Rule.Contains("@odata.type")) {
                        Write-Warning -Message "Detection rule is missing required '@odata.type' property. Use New-IntuneWin32AppDetectionRule* functions to create detection rules."
                        break
                    }
                    
                    # Validate @odata.type value
                    if ($Rule["@odata.type"] -notin $ValidDetectionTypes) {
                        Write-Warning -Message "Invalid detection rule type: $($Rule['@odata.type']). Valid types are: $($ValidDetectionTypes -join ', ')"
                        break
                    }
                }
                
                # Validate that correct detection rules have been passed on command line, only 1 PowerShell script based detection rule is allowed
                if (($DetectionRule.'@odata.type' -contains "#microsoft.graph.win32LobAppPowerShellScriptDetection") -and (@($DetectionRule).'@odata.type'.Count -gt 1)) {
                    Write-Warning -Message "Multiple PowerShell Script detection rules were detected, this is not a supported configuration"
                    break
                }
                
                # Add detection rules to Win32 app body object
                Write-Verbose -Message "Detection rule objects passed validation checks, attempting to add to existing Win32 app body"
                $Win32AppBody.Add("detectionRules", $DetectionRule)
            }

            try {
                # Attempt to call Graph and update Win32 app
                $Win32AppResponse = Invoke-MSGraphOperation -Patch -APIVersion "Beta" -Resource "deviceAppManagement/mobileApps/$($Win32AppID)" -Body ($Win32AppBody | ConvertTo-Json -Depth 3) -ErrorAction "Stop"
                Write-Verbose -Message "Successfully updated Win32 app object with ID: $($Win32AppID)"
                
                # Return the updated app object
                return $Win32AppResponse
            }
            catch [System.Exception] {
                Write-Warning -Message "An error occurred while update Win32 app object. Error message: $($_.Exception.Message)"
                throw
            }
        }
        else {
            Write-Warning -Message "Query for Win32 app returned an empty result, no apps matching the specified search criteria with ID '$($ID)' was found"
        }
    }
}
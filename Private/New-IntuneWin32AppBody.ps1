function New-IntuneWin32AppBody {
    <#
    .SYNOPSIS
        Retrieves meta data from the detection.xml file inside the packaged Win32 application .intunewin file.

    .DESCRIPTION
        Retrieves meta data from the detection.xml file inside the packaged Win32 application .intunewin file.

    .PARAMETER MSI
        Define that the Win32 application body will be MSI based.

    .PARAMETER EXE
        Define that the Win32 application body will be File based.
    
    .PARAMETER DisplayName
        Specify a display name for the Win32 application body.

    .PARAMETER Description
        Specify a description for the Win32 application body.

    .PARAMETER Publisher
        Specify a publisher name for the Win32 application body.

    .PARAMETER AppVersion
        Specify the app version for the Win32 application body.

    .PARAMETER Developer
        Specify a developer name for the Win32 application body.

    .PARAMETER Owner
        Specify the owner property for the Win32 application body.

    .PARAMETER Notes
        Specify the notes property for the Win32 application body.

    .PARAMETER InformationURL
        Specify the information URL for the Win32 application body.
    
    .PARAMETER PrivacyURL
        Specify the privacy URL for the Win32 application body.
    
    .PARAMETER CompanyPortalFeaturedApp
        Specify the featured in Company Portal property for the Win32 application body.

    .PARAMETER FileName
        Specify the file name (e.g. name.intunewin) for the Win32 application body.

    .PARAMETER SetupFileName
        Specify the setup file name (e.g. setup.exe) for the Win32 application body.
    
    .PARAMETER InstallExperience
        Specify the installation experience for the Win32 application body.
    
    .PARAMETER RestartBehavior
        Specify the installation experience for the Win32 application body.

    .PARAMETER RequirementRule
        Specify the requirement rules for the Win32 application body.

    .PARAMETER Icon
        Provide a Base64 encoded string as icon for the Win32 application body.

    .PARAMETER InstallCommandLine
        Specify the install command line for the Win32 application body.

    .PARAMETER UninstallCommandLine
        Specify the uninstall command line for the Win32 application body.
    
    .PARAMETER MSIInstallPurpose
        Specify the MSI installation purpose for the Win32 application body.
    
    .PARAMETER MSIProductCode
        Specify the MSI product code for the Win32 application body.

    .PARAMETER MSIProductName
        Specify the MSI product name for the Win32 application body.

    .PARAMETER MSIProductVersion
        Specify the MSI product version for the Win32 application body.
    
    .PARAMETER MSIRequiresReboot
        Specify the MSI requires reboot value for the Win32 application body.
    
    .PARAMETER MSIUpgradeCode
        Specify the MSI upgrade code for the Win32 application body.
            
    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-01-04
        Updated:     2022-09-02

        Version history:
        1.0.0 - (2020-01-04) Function created
        1.0.1 - (2020-01-27) Added support for RequirementRule parameter input
        1.0.2 - (2020-09-20) Added support for Owner, Notes, InformationURL, PrivacyURL and CompanyPortalFeaturedApp parameter inputs
        1.0.3 - (2021-08-31) Added AppVersion optional parameter
        1.0.3 - (2022-09-02) minimumSupportedOperatingSystem property is replaced by minimumSupportedWindowsRelease
                             Fixed a bug where minimumFreeDiskSpaceInMB, minimumMemoryInMB, minimumNumberOfProcessors and minimumCpuSpeedInMHz
                             would never contain any value since they're not handled by this function (https://github.com/MSEndpointMgr/IntuneWin32App/issues/44)
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, ParameterSetName = "MSI", HelpMessage = "Define that the Win32 application body will be MSI based.")]
        [switch]$MSI,

        [parameter(Mandatory = $true, ParameterSetName = "EXE", HelpMessage = "Define that the Win32 application body will be File based.")]
        [switch]$EXE,

        [parameter(Mandatory = $true, ParameterSetName = "MSI", HelpMessage = "Specify a display name for the Win32 application body.")]
        [parameter(Mandatory = $true, ParameterSetName = "EXE")]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [parameter(Mandatory = $true, ParameterSetName = "MSI", HelpMessage = "Specify a description for the Win32 application body.")]
        [parameter(Mandatory = $true, ParameterSetName = "EXE")]
        [ValidateNotNullOrEmpty()]
        [string]$Description,        

        [parameter(Mandatory = $true, ParameterSetName = "MSI", HelpMessage = "Specify a publisher name for the Win32 application body.")]
        [parameter(Mandatory = $true, ParameterSetName = "EXE")]
        [ValidateNotNullOrEmpty()]
        [string]$Publisher,

        [parameter(Mandatory = $false, ParameterSetName = "MSI", HelpMessage = "Specify the app version for the Win32 application body.")]
        [parameter(Mandatory = $false, ParameterSetName = "EXE")]
        [string]$AppVersion = [string]::Empty,

        [parameter(Mandatory = $false, ParameterSetName = "MSI", HelpMessage = "Specify a developer name for the Win32 application body.")]
        [parameter(Mandatory = $false, ParameterSetName = "EXE")]
        [string]$Developer = [string]::Empty,

        [parameter(Mandatory = $false, ParameterSetName = "MSI", HelpMessage = "Specify the owner property for the Win32 application body.")]
        [parameter(Mandatory = $false, ParameterSetName = "EXE")]
        [string]$Owner = [string]::Empty,

        [parameter(Mandatory = $false, ParameterSetName = "MSI", HelpMessage = "Specify the notes property for the Win32 application body.")]
        [parameter(Mandatory = $false, ParameterSetName = "EXE")]
        [string]$Notes = [string]::Empty,

        [parameter(Mandatory = $false, ParameterSetName = "MSI", HelpMessage = "Specify the information URL for the Win32 application body.")]
        [parameter(Mandatory = $false, ParameterSetName = "EXE")]
        [string]$InformationURL = [string]::Empty,

        [parameter(Mandatory = $false, ParameterSetName = "MSI", HelpMessage = "Specify the privacy URL for the Win32 application body.")]
        [parameter(Mandatory = $false, ParameterSetName = "EXE")]
        [string]$PrivacyURL = [string]::Empty,

        [parameter(Mandatory = $false, ParameterSetName = "MSI", HelpMessage = "Specify the featured in Company Portal property for the Win32 application body.")]
        [parameter(Mandatory = $false, ParameterSetName = "EXE")]
        [bool]$CompanyPortalFeaturedApp = $false,

        [parameter(Mandatory = $true, ParameterSetName = "MSI", HelpMessage = "Specify the file name (e.g. name.intunewin) for the Win32 application body.")]
        [parameter(Mandatory = $true, ParameterSetName = "EXE")]
        [ValidateNotNullOrEmpty()]
        [string]$FileName,

        [parameter(Mandatory = $true, ParameterSetName = "MSI", HelpMessage = "Specify the setup file name (e.g. setup.exe) for the Win32 application body.")]
        [parameter(Mandatory = $true, ParameterSetName = "EXE")]
        [ValidateNotNullOrEmpty()]
        [string]$SetupFileName,

        [parameter(Mandatory = $true, ParameterSetName = "MSI", HelpMessage = "Specify the installation experience for the Win32 application body.")]
        [parameter(Mandatory = $true, ParameterSetName = "EXE")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("system", "user")]
        [string]$InstallExperience,

        [parameter(Mandatory = $true, ParameterSetName = "MSI", HelpMessage = "Specify the installation experience for the Win32 application body.")]
        [parameter(Mandatory = $true, ParameterSetName = "EXE")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("allow", "basedOnReturnCode", "suppress", "force")]
        [string]$RestartBehavior,

        [parameter(Mandatory = $false, ParameterSetName = "MSI", HelpMessage = "Specify the requirement rules for the Win32 application body.")]
        [parameter(Mandatory = $false, ParameterSetName = "EXE")]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.OrderedDictionary]$RequirementRule,

        [parameter(Mandatory = $false, ParameterSetName = "MSI", HelpMessage = "Provide a Base64 encoded string as icon for the Win32 application body.")]
        [parameter(Mandatory = $false, ParameterSetName = "EXE")]
        [ValidateNotNullOrEmpty()]
        [string]$Icon,

        [parameter(Mandatory = $true, ParameterSetName = "EXE", HelpMessage = "Specify the install command line for the Win32 application body.")]
        [ValidateNotNullOrEmpty()]
        [string]$InstallCommandLine,

        [parameter(Mandatory = $true, ParameterSetName = "EXE", HelpMessage = "Specify the uninstall command line for the Win32 application body.")]
        [ValidateNotNullOrEmpty()]
        [string]$UninstallCommandLine,

        [parameter(Mandatory = $true, ParameterSetName = "MSI", HelpMessage = "Specify the MSI installation purpose for the Win32 application body.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("DualPurpose", "PerMachine", "PerUser")]
        [string]$MSIInstallPurpose,

        [parameter(Mandatory = $true, ParameterSetName = "MSI", HelpMessage = "Specify the MSI product code for the Win32 application body.")]
        [ValidateNotNullOrEmpty()]
        [string]$MSIProductCode,

        [parameter(Mandatory = $true, ParameterSetName = "MSI", HelpMessage = "Specify the MSI product name for the Win32 application body.")]
        [ValidateNotNullOrEmpty()]
        [string]$MSIProductName,

        [parameter(Mandatory = $true, ParameterSetName = "MSI", HelpMessage = "Specify the MSI product version for the Win32 application body.")]
        [ValidateNotNullOrEmpty()]
        [string]$MSIProductVersion,

        [parameter(Mandatory = $true, ParameterSetName = "MSI", HelpMessage = "Specify the MSI requires reboot value for the Win32 application body.")]
        [ValidateNotNullOrEmpty()]
        [bool]$MSIRequiresReboot,

        [parameter(Mandatory = $true, ParameterSetName = "MSI", HelpMessage = "Specify the MSI upgrade code for the Win32 application body.")]
        [ValidateNotNullOrEmpty()]
        [string]$MSIUpgradeCode
    )
    # Determine values for requirement rules
    if ($PSBoundParameters["RequirementRule"]) {
        # Define required requirement rules propertoes
        $ApplicableArchitectures = $RequirementRule["applicableArchitectures"]
        $MinimumSupportedWindowsRelease = $RequirementRule["minimumSupportedWindowsRelease"]
    }
    else {
        $ApplicableArchitectures = "x64,x86"
        $MinimumSupportedWindowsRelease = "2H20"
    }

    switch ($PSCmdlet.ParameterSetName) {
        "MSI" {
            $Win32AppBody = [ordered]@{
                "@odata.type" = "#microsoft.graph.win32LobApp"
                "applicableArchitectures" = $ApplicableArchitectures
                "description" = $Description
                "developer" = $Developer
                "displayVersion" = $AppVersion
                "owner" = $Owner
                "notes" = $Notes
                "informationUrl" = $InformationURL
                "privacyInformationUrl" = $PrivacyURL
                "isFeatured" = $CompanyPortalFeaturedApp
                "displayName" = $DisplayName
                "fileName" = $FileName
                "setupFilePath" = $SetupFileName
                "installCommandLine" = "msiexec.exe /i `"$SetupFileName`""
                "uninstallCommandLine" = "msiexec.exe /x `"$MSIProductCode`""
                "installExperience" = @{
                    "runAsAccount" = $InstallExperience
                    "deviceRestartBehavior" = $RestartBehavior
                }
                "minimumSupportedWindowsRelease" = $MinimumSupportedWindowsRelease
                "minimumFreeDiskSpaceInMB" = if ($RequirementRule["minimumFreeDiskSpaceInMB"]) { $RequirementRule["minimumFreeDiskSpaceInMB"] } else { "" }
                "minimumMemoryInMB" = if ($RequirementRule["minimumMemoryInMB"]) { $RequirementRule["minimumMemoryInMB"] } else { "" }
                "minimumNumberOfProcessors" = if ($RequirementRule["minimumNumberOfProcessors"]) { $RequirementRule["minimumNumberOfProcessors"] } else { "" }
                "minimumCpuSpeedInMHz" = if ($RequirementRule["minimumCpuSpeedInMHz"]) { $RequirementRule["minimumCpuSpeedInMHz"] } else { "" }
                "msiInformation" = @{
                    "packageType" = $MSIInstallPurpose
                    "productCode" = $MSIProductCode
                    "productName" = $MSIProductName
                    "productVersion" = $MSIProductVersion
                    "publisher" = $MSIPublisher
                    "requiresReboot" = $MSIRequiresReboot
                    "upgradeCode" = $MSIUpgradeCode
                }
                "publisher" = $Publisher
                "runAs32bit" = $false
            }

            # Add icon property if passed on command line
            if ($PSBoundParameters["Icon"]) {
                $Win32AppBody.Add("largeIcon", @{
                    "type" = "image/png"
                    "value" = $Icon
                })
            }
        }
        "EXE" {
            $Win32AppBody = [ordered]@{
                "@odata.type" = "#microsoft.graph.win32LobApp"
                "applicableArchitectures" = $ApplicableArchitectures
                "description" = $Description
                "developer" = $Developer
                "displayVersion" = $AppVersion
                "owner" = $Owner
                "notes" = $Notes
                "informationUrl" = $InformationURL
                "privacyInformationUrl" = $PrivacyURL
                "isFeatured" = $CompanyPortalFeaturedApp
                "displayName" = $DisplayName
                "fileName" = $FileName
                "setupFilePath" = $SetupFileName
                "installCommandLine" = $InstallCommandLine
                "uninstallCommandLine" = $UninstallCommandLine
                "installExperience" = @{
                    "runAsAccount" = $InstallExperience
                    "deviceRestartBehavior" = $RestartBehavior
                }
                "minimumSupportedWindowsRelease" = $MinimumSupportedWindowsRelease
                "msiInformation" = $null
                "publisher" = $Publisher
                "runAs32bit" = $false
            }

            # Add icon property if passed on command line
            if ($PSBoundParameters["Icon"]) {
                $Win32AppBody.Add("largeIcon", @{
                    "type" = "image/png"
                    "value" = $Icon
                })
            }
        }
    }

    # Handle return value with constructed Win32 application body
    return $Win32AppBody
}
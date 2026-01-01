# Get MSI meta data from .intunewin file
$IntuneWinFile = "C:\IntuneWin32App\Output\7z1900-x64.intunewin"
$IntuneWinMetaData = Get-IntuneWin32AppMetaData -FilePath $IntuneWinFile


# Create custom display name like 'Name' and 'Version'
$DisplayName = $IntuneWinMetaData.ApplicationInfo.Name + " " + $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductVersion


# Create MSI detection rule
$DetectionRuleArguments = @{
    "ProductCode" = $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductCode
    "ProductVersionOperator" = "greaterThanOrEqual"
    "ProductVersion" = $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductVersion
}
$DetectionRule = New-IntuneWin32AppDetectionRuleMSI @DetectionRuleArguments


# Create operative system requirement rule
# Examples of different architecture options:
# $RequirementRule = New-IntuneWin32AppRequirementRule -Architecture "x64" -MinimumSupportedWindowsRelease "W10_22H2"        # x64 only
# $RequirementRule = New-IntuneWin32AppRequirementRule -Architecture "arm64" -MinimumSupportedWindowsRelease "W10_22H2"      # ARM64 only
# $RequirementRule = New-IntuneWin32AppRequirementRule -Architecture "AllWithARM64" -MinimumSupportedWindowsRelease "W10_22H2" # x64, x86, and ARM64
$RequirementRule = New-IntuneWin32AppRequirementRule -Architecture "x64x86" -MinimumSupportedWindowsRelease "W10_22H2"


# Create custom return code
$ReturnCode = New-IntuneWin32AppReturnCode -ReturnCode 1337 -Type retry


# Construct a table of default parameters for the Win32 app
$Win32AppArgs = @{
    "FilePath" = $IntuneWinFile
    "DisplayName" = $DisplayName
    "Description" = "App description"
    "Publisher" = "MSEndpointMgr"
    "AppVersion" = $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductVersion
    "InstallExperience" = "system"
    "RestartBehavior" = "suppress"
    "DetectionRule" = $DetectionRule
    "RequirementRule" = $RequirementRule
    "ReturnCode" = $ReturnCode
    "Verbose" = $true
}
Add-IntuneWin32App @Win32AppArgs
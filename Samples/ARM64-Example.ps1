# Example: Creating a Win32 app with ARM64 support
# This example demonstrates how to create Win32 apps targeting ARM64 devices
# using the new allowedArchitectures property

# Get MSI meta data from .intunewin file
$IntuneWinFile = "C:\IntuneWin32App\Output\MyApp-Universal.intunewin"
$IntuneWinMetaData = Get-IntuneWin32AppMetaData -FilePath $IntuneWinFile

# Create custom display name
$DisplayName = $IntuneWinMetaData.ApplicationInfo.Name + " " + $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductVersion

# Create MSI detection rule
$DetectionRule = New-IntuneWin32AppDetectionRuleMSI -ProductCode $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductCode -ProductVersionOperator "greaterThanOrEqual" -ProductVersion $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductVersion

# Example 1: ARM64 only targeting (for native ARM64 apps)
$RequirementRuleARM64 = New-IntuneWin32AppRequirementRule -Architecture "arm64" -MinimumSupportedWindowsRelease "W11_21H2"

# Example 2: Universal targeting (x64, x86, and ARM64)
$RequirementRuleUniversal = New-IntuneWin32AppRequirementRule -Architecture "AllWithARM64" -MinimumSupportedWindowsRelease "W10_22H2"

# Example 2: x64 and ARM64 only (manual creation for advanced scenarios)
$RequirementRuleModern = @{
    "allowedArchitectures" = "x64,arm64"
    "applicableArchitectures" = "none" 
    "minimumSupportedWindowsRelease" = "Windows10_22H2"
}

# Create return code
$ReturnCode = New-IntuneWin32AppReturnCode -ReturnCode 0 -Type "success"

# Example app arguments for ARM64-only deployment
$Win32AppArgsARM64 = @{
    "FilePath" = $IntuneWinFile
    "DisplayName" = "$DisplayName (ARM64)"
    "Description" = "ARM64 native version of $($IntuneWinMetaData.ApplicationInfo.Name)"
    "Publisher" = $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiPublisher
    "AppVersion" = $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductVersion
    "InstallExperience" = "system"
    "RestartBehavior" = "suppress"
    "DetectionRule" = $DetectionRule
    "RequirementRule" = $RequirementRuleARM64
    "ReturnCode" = $ReturnCode
    "Verbose" = $true
}

# Example app arguments for universal deployment
$Win32AppArgsUniversal = @{
    "FilePath" = $IntuneWinFile
    "DisplayName" = "$DisplayName (Universal)"
    "Description" = "Universal version supporting x64, x86, and ARM64 architectures"
    "Publisher" = $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiPublisher
    "AppVersion" = $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductVersion
    "InstallExperience" = "system"
    "RestartBehavior" = "suppress"
    "DetectionRule" = $DetectionRule
    "RequirementRule" = $RequirementRuleUniversal
    "ReturnCode" = $ReturnCode
    "Verbose" = $true
}

# Example app arguments for x64+ARM64 deployment (manual requirement rule)
$Win32AppArgsModern = @{
    "FilePath" = $IntuneWinFile
    "DisplayName" = "$DisplayName (x64+ARM64)"
    "Description" = "Deployment targeting x64 and ARM64 architectures only"
    "Publisher" = $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiPublisher
    "AppVersion" = $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductVersion
    "InstallExperience" = "system"
    "RestartBehavior" = "suppress"
    "DetectionRule" = $DetectionRule
    "RequirementRule" = $RequirementRuleModern
    "ReturnCode" = $ReturnCode
    "Verbose" = $true
}

# Uncomment one of the following to create the app:

# Create ARM64-only app
# Add-IntuneWin32App @Win32AppArgsARM64

# Create universal app (recommended for most scenarios)
# Add-IntuneWin32App @Win32AppArgsUniversal

# Create x64+ARM64 app (for advanced scenarios requiring manual requirement rule)
# Add-IntuneWin32App @Win32AppArgsModern

Write-Host "ARM64 Win32 App examples configured. Uncomment the desired Add-IntuneWin32App line to create the app." -ForegroundColor Green
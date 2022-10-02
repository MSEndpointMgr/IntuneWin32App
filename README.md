# Overview
![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/IntuneWin32App)

This module was created to provide means to automate the packaging, creation and publishing of Win32 applications in Microsoft Intune.

Currently the following functions are supported in the module:
- Add-IntuneWin32App
- Add-IntuneWin32AppAssignment
- Add-IntuneWin32AppAssignmentAllDevices
- Add-IntuneWin32AppAssignmentAllUsers
- Add-IntuneWin32AppAssignmentGroup
- Add-IntuneWin32AppDependency
- Add-IntuneWin32AppSupersedence
- Connect-MSIntuneGraph
- Expand-IntuneWin32AppPackage
- Get-IntuneWin32App
- Get-IntuneWin32AppAssignment
- Get-IntuneWin32AppDependency
- Get-IntuneWin32AppMetaData
- Get-IntuneWin32AppSupersedence
- Get-MSIMetaData
- New-IntuneWin32AppDependency
- New-IntuneWin32AppDetectionRule
- New-IntuneWin32AppDetectionRuleFile
- New-IntuneWin32AppDetectionRuleMSI
- New-IntuneWin32AppDetectionRuleRegistry
- New-IntuneWin32AppDetectionRuleScript
- New-IntuneWin32AppIcon
- New-IntuneWin32AppPackage
- New-IntuneWin32AppRequirementRule
- New-IntuneWin32AppRequirementRuleFile
- New-IntuneWin32AppRequirementRuleRegistry
- New-IntuneWin32AppRequirementRuleScript
- New-IntuneWin32AppReturnCode
- New-IntuneWin32AppSupersedence
- Remove-IntuneWin32App
- Remove-IntuneWin32AppAssignment
- Remove-IntuneWin32AppDependency
- Remove-IntuneWin32AppSupersedence
- Update-IntuneWin32AppPackageFile

## Installing the module from PSGallery
The IntuneWin32App module is published to the PowerShell Gallery. Install it on your system by running the following in an elevated PowerShell console:
```PowerShell
Install-Module -Name "IntuneWin32App" -AcceptLicense
```

## Module dependencies
IntuneWin32App module requires the following modules, which will be automatically installed as dependencies:
- MSAL.PS

## Authentication
In the previous versions of this module, the functions that interact with Microsoft Intune (essentially query the Graph API for resources), used have common parameters that required input on a per function basis. With the release of version 1.2.0 and going forward, the IntuneWin32App module replaces these common parameter requirements and replaces them with a single function, Connect-MSIntuneGraph, to streamline the authentication token retrieval with other modules and how they work.

Before using any of the functions within this module that interacts with Graph API, ensure that an authentication token is acquired using the following command:
```PowerShell
Connect-MSIntuneGraph -TenantID "domain.onmicrosoft.com"
```

Delegated authentication (username / password) together with DeviceCode is currently the only authentication methods that are supported.

## Encoding recommendations
When for instance UTF-8 encoding is required, ensure the file is encoded with UTF-8 with BOM, this should address some problems reported in the past where certain characters was not shown correctly in the MEM portal.

Below is a screenshot from Visual Studio Code where the encoding is set accordingly:

![image](https://user-images.githubusercontent.com/14348341/193473947-bf7d615e-c4b1-4335-a62c-7b0b899724e4.png)

## Get existing Win32 apps
Get-IntuneWin32App function can be used to retrieve existing Win32 apps in Microsoft Intune. Retrieving an existing Win32 app could either be done passing the display name of the app, which performs a wildcard search meaning it's not required to specify the full name of the Win32 app. The ID if a specific Win32 app could also be used for this function. Additionally, by not specifying either a display name or an ID, all Win32 apps available will be retrieved. Below are a few examples of how this function could be used:
```PowerShell
# Get all Win32 apps
Get-IntuneWin32App -Verbose

# Get a specific Win32 app by it's display name
Get-IntuneWin32App -DisplayName "7-zip" -Verbose

# Get a specific Win32 app by it's id
Get-IntuneWin32App -ID "<Win32 app ID>" -Verbose
```

## Package application source files into Win32 app package (.intunewin)
Use the New-IntuneWin32AppPackage function in the module to create a content package for a Win32 app. MSI, EXE and script-based applications are supported by this function. This function automatically downloads the IntuneWinAppUtil.exe application that's essentially the engine behind the packaging and encryption process. The utility will be downloaded to the temporary directory of the user running the function, more specifically the location of the environment variable %TEMP%. If required, a custom path to where IntuneWinAppUtil.exe already exists is possible to pass to the function using the IntuneWinAppUtilPath parameter. In the sample below, application source files for 7-Zip including the setup file are specified and being packaged into an .intunewin encrypted file. Package will be exported to the output folder.
```PowerShell
# Package MSI as .intunewin file
$SourceFolder = "C:\Win32Apps\Source\7-Zip"
$SetupFile = "7z1900-x64.msi"
$OutputFolder = "C:\Win32Apps\Output"
New-IntuneWin32AppPackage -SourceFolder $SourceFolder -SetupFile $SetupFile -OutputFolder $OutputFolder -Verbose
```

## Create a new MSI based installation as a Win32 app
Use the New-IntuneWin32AppPackage function to first create the packaged Win32 app content file (.intunewin). Then call the Add-IntuneWin32App function to create a new Win32 app in Microsoft Intune. This function has dependencies for other functions in the module. For instance when passing the detection rule for the Win32 app, you need to use the New-IntuneWin32AppDetectionRule function to create the required input object. Below is an example how the dependent functions in this module can be used together with the Add-IntuneWin32App function to successfully upload a packaged Win32 app content file to Microsoft Intune:
```PowerShell
# Get MSI meta data from .intunewin file
$IntuneWinFile = "C:\Win32Apps\Output\7z1900-x64.intunewin"
$IntuneWinMetaData = Get-IntuneWin32AppMetaData -FilePath $IntuneWinFile

# Create custom display name like 'Name' and 'Version'
$DisplayName = $IntuneWinMetaData.ApplicationInfo.Name + " " + $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductVersion
$Publisher = $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiPublisher

# Create requirement rule for all platforms and Windows 10 20H2
$RequirementRule = New-IntuneWin32AppRequirementRule -Architecture "All" -MinimumSupportedWindowsRelease "20H2"

# Create MSI detection rule
$DetectionRule = New-IntuneWin32AppDetectionRuleMSI -ProductCode $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductCode -ProductVersionOperator "greaterThanOrEqual" -ProductVersion $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductVersion

# Add new MSI Win32 app
Add-IntuneWin32App -FilePath $IntuneWinFile -DisplayName $DisplayName -Description "Install 7-zip application" -Publisher $Publisher -InstallExperience "system" -RestartBehavior "suppress" -DetectionRule $DetectionRule -RequirementRule $RequirementRule -Verbose
```

## Create a new EXE/script based installation as a Win32 app
Use the New-IntuneWin32AppPackage function to first create the packaged Win32 app content file (.intunewin). Then call the Add-IntuneWin32App much like the example above illustrates for a MSI installation based Win32 app. Apart from the above example, for an EXE/script based Win32 app, a few other parameters are required:
- InstallCommandLine
- UninstallCommandLine

The detection rule is also constructed differently, for example in the below script it's using a PowerShell script as the detection logic. In the example below a Win32 app is created that's essentially a PowerShell script that executes and another PowerShell script used for detection:
```PowerShell
# Get MSI meta data from .intunewin file
$IntuneWinFile = "C:\Win32Apps\Output\Enable-BitLockerEncryption.intunewin"
$IntuneWinMetaData = Get-IntuneWin32AppMetaData -FilePath $IntuneWinFile

# Create custom display name like 'Name' and 'Version'
$DisplayName = "Enable BitLocker Encryption 1.0"

# Create requirement rule for all platforms and Windows 10 20H2
$RequirementRule = New-IntuneWin32AppRequirementRule -Architecture "All" -MinimumSupportedWindowsRelease "20H2"

# Create PowerShell script detection rule
$DetectionScriptFile = "C:\Win32Apps\Output\Get-BitLockerEncryptionDetection.ps1"
$DetectionRule = New-IntuneWin32AppDetectionRuleScript -ScriptFile $DetectionScriptFile -EnforceSignatureCheck $false -RunAs32Bit $false

# Add new EXE Win32 app
$InstallCommandLine = "powershell.exe -ExecutionPolicy Bypass -File .\Enable-BitLockerEncryption.ps1"
$UninstallCommandLine = "cmd.exe /c"
Add-IntuneWin32App -FilePath $IntuneWinFile -DisplayName $DisplayName -Description "Start BitLocker silent encryption" -Publisher "MSEndpointMgr" -InstallExperience "system" -RestartBehavior "suppress" -DetectionRule $DetectionRule -RequirementRule $RequirementRule -ReturnCode $ReturnCode -InstallCommandLine $InstallCommandLine -UninstallCommandLine $UninstallCommandLine -Verbose
```

## Additional parameters for Add-IntuneWin32App function
When creating a Win32 app, additional configuration is possible when using the Add-IntuneWin32App function. It's possible to set the icon for the Win32 app using the Icon parameter. If desired, it's also possible to add custom, in addition to the default, return codes by adding the ReturnCode parameter. Below is an example of how the Add-IntuneWin32App function could be extended with those parameters by using the New-IntuneWin32AppIcon and New-IntuneWin32AppReturnCode functions:

```PowerShell
# Create custom return code
$ReturnCode = New-IntuneWin32AppReturnCode -ReturnCode 1337 -Type "retry"

# Convert image file to icon
$ImageFile = "C:\Win32Apps\Logos\Image.png"
$Icon = New-IntuneWin32AppIcon -FilePath $ImageFile
```

## Create a Win32 app assignment
IntuneWin32App module also supports adding assignments. Since version 1.2.0, functionality for creating an assignment for an existing Win32 app in Microsoft Intune (or one created with the Add-IntuneWin32App function), are aligned with the new functionality released for Win32 apps over the recent service releases of Intune, and includes the following taregeting possibilities:
- All Users
- All Devices
- Specified group

Assignments created with this module doesn't currently support specifying an installation deadline or available time. The assignment will by default be created with the settings for installation deadline and availability configured as 'As soon as possible'. Below is an example of how to add assignments using the module:
### Adding for a group
```PowerShell
# Get a specific Win32 app by it's display name
$Win32App = Get-IntuneWin32App -DisplayName "7-zip" -Verbose

# Add an include assignment for a specific Azure AD group
$GroupID = "<Azure AD group ID>"
Add-IntuneWin32AppAssignmentGroup -Include -ID $Win32App.id -GroupID $GroupID -Intent "available" -Notification "showAll" -Verbose
```
### Adding for all users
```PowerShell
# Get a specific Win32 app by it's display name
$Win32App = Get-IntuneWin32App -DisplayName "7-zip" -Verbose

# Add assignment for all users
Add-IntuneWin32AppAssignmentAllUsers -ID $Win32App.id -Intent "available" -Notification "showAll" -Verbose
```
### Adding for all devices
```PowerShell
# Get a specific Win32 app by it's display name
$Win32App = Get-IntuneWin32App -DisplayName "7-zip" -Verbose

# Add assignment for all devices
Add-IntuneWin32AppAssignmentAllDevices -ID $Win32App.id -Intent "available" -Notification "showAll" -Verbose
```

## Expand
The New-IntuneWin32AppPackage function packages and encrypts a Win32 app content file (.intunewin file). This file can be uncompressed using any decompression tool, e.g. 7-Zip. Inside the file resides a folder structure resides essentially two important files for that's required for the Expand-IntuneWin32AppPackage function. These two files, detection.xml <PackageName>.intunewin, was generated when IntuneWinAppUtil.exe executed. Detection.xml contains the encryption info, more specifically the encryptionKey and initializationVector details. <PackageName>.intunewin is the actual encrypted file, that with the encryptionKey and initializationVector info, can be decrypted. This function can 'expand', meaning to uncompress and decrypt the original Win32 app content file containing the two files already mentioned, but does not support decryption only of the <PackageName>.intunewin file that was already uploaded to Microsoft Intune for a given Win32 app and then later downloaded from the Azure Storage blob associated with that app. This is because Graph API does not expose the encryptionKey and initializationVector data once a Win32 app content file has been uploaded to Microsoft Intune. A request to expose this data in Graph API has been sent to Microsoft, but the future will tell if they decide to fullfil that request. Below is an example of how to use the Expand-IntuneWin32AppPackage function using the full Win32 app content file created either manually with IntuneWinAppUtil.exe or with the New-IntuneWin32AppPackage function:

```PowerShell
# Decode an existing Win32 app content file
$IntuneWinFile = "C:\Win32Apps\Output\7z1900-x64.intunewin"
Expand-IntuneWin32AppPackage -FilePath $IntuneWinFile -Force -Verbose
```

## Full example of packaging and creating a Win32 app
Below is an example that automates the complete process of creating the Win32 app content file, adding a new Win32 app in Microsoft Intune and assigns it to all users.

```PowerShell
# Package MSI as .intunewin file
$SourceFolder = "C:\Win32Apps\Source\7-Zip"
$SetupFile = "7z1900-x64.msi"
$OutputFolder = "C:\Win32Apps\Output"
$Win32AppPackage = New-IntuneWin32AppPackage -SourceFolder $SourceFolder -SetupFile $SetupFile -OutputFolder $OutputFolder -Verbose

# Get MSI meta data from .intunewin file
$IntuneWinFile = $Win32AppPackage.Path
$IntuneWinMetaData = Get-IntuneWin32AppMetaData -FilePath $IntuneWinFile

# Create custom display name like 'Name' and 'Version'
$DisplayName = $IntuneWinMetaData.ApplicationInfo.Name + " " + $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductVersion
$Publisher = $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiPublisher

# Create requirement rule for all platforms and Windows 10 20H2
$RequirementRule = New-IntuneWin32AppRequirementRule -Architecture "All" -MinimumSupportedWindowsRelease "20H2"  
  
# Create MSI detection rule
$DetectionRule = New-IntuneWin32AppDetectionRuleMSI -ProductCode $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductCode -ProductVersionOperator "greaterThanOrEqual" -ProductVersion $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductVersion

# Create custom return code
$ReturnCode = New-IntuneWin32AppReturnCode -ReturnCode 1337 -Type "retry"

# Convert image file to icon
$ImageFile = "C:\Win32Apps\Logos\7-Zip.png"
$Icon = New-IntuneWin32AppIcon -FilePath $ImageFile

# Add new MSI Win32 app
$Win32App = Add-IntuneWin32App -FilePath $IntuneWinFile -DisplayName $DisplayName -Description "Install 7-zip application" -Publisher $Publisher -InstallExperience "system" -RestartBehavior "suppress" -DetectionRule $DetectionRule -RequirementRule $RequirementRule -ReturnCode $ReturnCode -Icon $Icon -Verbose

# Add assignment for all users
Add-IntuneWin32AppAssignmentAllUsers -ID $Win32App.id -Intent "available" -Notification "showAll" -Verbose
```

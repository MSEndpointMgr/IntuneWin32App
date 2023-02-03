# Release notes for IntuneWin32App module

## 1.4.0
- Properly fixed the issue with the public `New-IntuneWin32AppRequirementRule` and the private `New-IntuneWin32AppBody` functions to ensure the minimumFreeDiskSpaceInMB, MinimumMemoryInMB, MinimumNumberOfProcessors and minimumCpuSpeedInMHz objets are dynamically added to the request body, only if specificed on the command line with the `New-IntuneWin32AppRequirementRule` function.
- Added parameter AzCopyWindowStyle to `Add-IntuneWin32App` function, to support what's discussed in issue #64.
- Updated public `Add-IntuneWin32App`, `New-IntuneWin32AppIcon`, `Expand-IntuneWin32AppPackage`, `Get-IntuneWin32AppMetaData`, `New-IntuneWin32AppDetectionRuleScript`, `New-IntuneWin32AppRequirementRuleScript`, `Update-IntuneWin32AppPackageFile` and private `Expand-IntuneWin32AppCompressedFile` functions with improved file name validation which replaces the regex validation which was prohibiting usage of the module on non-Windows platforms, but also preventing accessing files on network shares.
- Added support for a new parameter named ScopeTagName for the `Add-IntuneWin32App` function. Scope Tags can now be added when creating the Win 32 application in Intune. This parameter supports multiple Scope Tags to be added at the same time.
- Improved error handling in `Invoke-AzureADGraphRequest` and `Invoke-IntuneGraphRequest` functions reported in issue #65.
- Added UnattendedInstall and UnattendedUninstall parameter switches to the `Add-IntuneWin32App` function. For MSI based setup installers, you can now specify whether to automatically append the install and/or uninstall command lines with the /quiet switch.
- Fixed bug reported in issue #57.
- `New-IntuneWin32AppPackage` function now uses the -q switch when invoking the IntuneWinAppUtil.exe wrapper utility. In addition to this, the check for existing .intunewin file has been embeded into the function itself, where the new Force parameter can be used to always overwrite an existing .intunewin file in the output directory.
- Added a new function named `Set-IntuneWin32App`. Use this function to update properties of an existing Win32 app in Intune, for instance to change the app version, description, display name, owner or notes among other properties.
- Added a new function named `Get-IntuneWin32AppCategory`, to retrieve a given mobile app category, also referred to as category, by display name or to list all available categories.
- Updated `Add-IntuneWin32App` function with a new parameter named CategoryName, that supports multiple category names, to add support for adding categories to the Win32 app when creating it.
- Updated `Add-IntuneWin32App` function with a new behavior when the UseAzCopy switch is used, to fallback to the native file transfer method if the content size is less than 100MB.
- Deprecated and removed the `Add-IntuneWin32AppAssignment` function, use the following functions instead to manage all assignments aspects: `Add-IntuneWin32AppAssignmentAllDevices`, `Add-IntuneWin32AppAssignmentAllUsers`, `Add-IntuneWin32AppAssignmentGroup`.
- Deprecated and removed the `New-IntuneWin32AppDetectionRuleFile` function, use the following functions instead to manage all detection rule aspects: `New-IntuneWin32AppDetectionRuleFile`, `New-IntuneWin32AppDetectionRuleMSI`, `New-IntuneWin32AppDetectionRuleRegistry`, `New-IntuneWin32AppDetectionRuleScript`.

## 1.3.6
- Add-IntuneWin32App function now has a new parameter switch named UseAzCopy. When this switch is used, AzCopy.exe is used to transfer the files to the storage account instead of the native method.
- New-IntuneWin32AppRequirementRule has been updated to construct the proper objects. The minimumFreeDiskSpaceInMB, MinimumMemoryInMB, MinimumNumberOfProcessors and minimumCpuSpeedInMHz objects when not specified as parameters now adds a 'null' string instead of $null (not being part of the object returned).
- Private function Invoke-IntuneGraphRequest has been updated with UTF-8 encoding content type support. From this version and on, when the script file is properly encoded with UTF-8 with BOM, special characters should now work as expected.

## 1.3.5
- Connect-MSIntuneGraph function has been updated to store the TenantID parameter in a global variable named $Global:AccessTokenTenantID.
- Private function Invoke-AzureStorageBlobUpload used in Add-IntuneWin32App function now refreshes an access token 10 minutes before it's about to expire. This should prevent uploads of large applications from failing due to the access token has expired.

## 1.3.4
- Private function New-IntuneWin32AppBody used in Add-IntuneWin32App function, was updated where the minimumSupportedOperatingSystem property is replaced by minimumSupportedWindowsRelease. This caused the Add-IntuneWin32App function to return Bad Request since the request body was malformed. `NOTE:` This change introduces a new parameter for New-IntuneWin32AppRequirementRule function named MinimumSupportedWindowsRelease that replaces the MinimumSupportedOperatingSystem parameter.
- Also fixed a bug in private function New-IntuneWin32AppBody where minimumFreeDiskSpaceInMB, minimumMemoryInMB, minimumNumberOfProcessors and minimumCpuSpeedInMHz properties where not handled at all. 
- Add-IntuneWin32App function was updated where a break command that would prevent the Win32 app body JSON output from being display in case an error occured, was removed.
- New-IntuneWin32AppRequirementRuleScript and New-IntuneWin32AppDetectionRuleScript functions was fixed as reported on: https://github.com/MSEndpointMgr/IntuneWin32App/issues/41
- New-IntuneWin32AppRequirementRuleScript has been updated with correct variables for 'Version'.

## 1.3.3
- Added ClientSecret parameter in the Connect-MSIntuneGraph function to support the client secret auth flow

## 1.3.2
- New-IntuneWin32AppReturnCode function now supports Failed as a return code type
- Fixed an issue where the ExpiresOn property of the access token was stored in local time instead of UTC

## 1.3.1
- Added AppVersion optional parameter for Add-IntuneWin32App function
- Fixed an issue in the Update-IntuneWin32AppPackageFile function where the PATCH operation would remove the largeIcon property value of the Win32 app
- Fixed an issue in the New-IntuneWin32AppDetectionRuleScript and New-IntuneWin32AppRequirementRuleScript functions when using a non-UTF encoded multi-line script file, it would not be imported to Intune

## 1.3.0
- Switched from PSIntuneAuth module to use the MSAL.PS module. Delegated authentication including DeviceCode flows are now supported.
- New function added to extend the functionality of the module:
  - Remove-IntuneWin32App
  - Get-IntuneWin32AppDependency
  - New-IntuneWin32AppDependency
  - Add-IntuneWin32AppDependency
  - Remove-IntuneWin32AppDependency
  - Get-IntuneWin32AppSupersedence
  - New-IntuneWin32AppSupersedence
  - Add-IntuneWin32AppSupersedence
  - Remove-IntuneWin32AppSupersedence

## 1.2.1
- Get-IntuneWin32AppAssignment function now includes the GroupMode property (Include/Exclude) in the output
- Add-IntuneWin32App function includes a fix in private functions it relies upon to successfully upload the packaged content. This fix addresses bug #3 where the SAS Uri renewal process wasn't working properly.

## 1.2.0
- Connect-MSIntuneGraph function has been added to replace the TenantName parameter for all functions that requires an authentication token. Use this function to retrieve the authentication token before running any of the functions that creates, updates or changes any aspect of a Win32 app.
- New functions added to extend the functionality of the module:
  - Connect-MSIntuneGraph
  - New-IntuneWin32AppDetectionRuleScript
  - New-IntuneWin32AppDetectionRuleMSI
  - New-IntuneWin32AppDetectionRuleRegistry
  - New-IntuneWin32AppDetectionRuleFile
  - Update-IntuneWin32AppPackageFile
  - Add-IntuneWin32AppAssignmentAllDevices
  - Add-IntuneWin32AppAssignmentAllUsers
  - Add-IntuneWin32AppAssignmentGroup
  - New-IntuneWin32AppRequirementRuleScript
  - New-IntuneWin32AppRequirementRuleRegistry
  - New-IntuneWin32AppRequirementRuleFile
  - Get-IntuneWin32AppAssignment
  - Remove-IntuneWin32AppAssignment
- Add-IntuneWin32AppAssignment function is deprecated from this release going forward, use any of the new functions added in this release, for instance Add-IntuneWin32AppAssignmentGroup.
- New-IntuneWin32AppDetectionRule function is deprecated from this release going forward, use any of the new functions added in this release, for instance New-IntuneWin32AppDetectionRuleMSI.
- Add-IntuneWin32App function now supports additional properties, such as Information URL, Display app in Company Portal, Privacy URL, Developer, Owner and Comments.
- Add-IntuneWin32AppAssignmentAllDevices, Add-IntuneWin32AppAssignmentAllUsers and Add-IntuneWin32AppAssignmentGroup functions now support restart settings including available and deadline configurations.
- Add-IntuneWin32App function now cleans up the sub-folder created with the extracted .intunewin file.
- Get-IntuneWin32AppAssignment function has a new parameter called GroupName, that can be used to retrieve a list of the assignments targeted for a given group.

## 1.1.1
- Improved output for attempting to update the PSIntuneAuth module in the internal Get-AuthToken function.

## 1.1.0
- Added a new function called Get-MSIMetaData to retrieve MSI file properties like ProductCode and more.
- Added a new function called New-IntuneWin32AppRequirementRule to create a customized requirement rule for the Win32 app. This function does not support 'Additional requirement rules' as of yet, but will be implemented in a future version.
- Function Add-IntuneWin32App now supports an optional RequirementRule parameter. Use New-IntuneWin32AppRequirementRule function to create a suitable object for this parameter. If the RequirementRule parameter is not specified for Add-IntuneWin32App, default values of 'applicableArchitectures' with a value of 'x64,x86' and 'minimumSupportedOperatingSystem' with a value of 'v10_1607' will be used when adding the Win32 app.

## 1.0.1
- Updated Get-IntuneWin32App function to load all properties for objects return and support multiple objects returned for wildcard search when specifying display name.

## 1.0.0
- Initial release, se README.md for documentation.
# Release notes for IntuneWin32App module

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
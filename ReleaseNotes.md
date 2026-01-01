# Release notes for IntuneWin32App module

## 1.5.0
- **BREAKING CHANGE**: Updated `New-IntuneWin32AppRequirementRule` function to support ARM64 architecture and switched to modern `allowedArchitectures` property by default
- **BREAKING CHANGE**: Updated `Connect-MSIntuneGraph` function to require explicit ClientID parameter - removed deprecated Microsoft Intune PowerShell enterprise application fallback
- **ENHANCEMENT**: Merged PR #162 - Comprehensive retry logic and authentication improvements for production reliability
- Added robust retry mechanisms throughout the module with exponential backoff for transient failures (429 rate limiting, 503 service unavailable)
- Implemented retry logic for Win32 app creation, content version creation, file content creation, and Azure Storage blob operations
- Added new `New-ClientCredentialsAccessToken` function for modern OAuth2.0 client credentials flow without MSAL.PS dependency
- Enhanced `Test-AccessToken` function with improved token expiration handling using locale-safe DateTimeOffset parsing
- Updated `Invoke-IntuneGraphRequest` with comprehensive retry logic (up to 10 attempts with configurable delays)
- Improved Azure Storage blob upload reliability with retry logic in chunk uploads and finalization steps
- Fixed locale-specific DateTime conversion issues in token expiration calculations for international environments
- Added missing `content-type` header to Azure Storage blob upload finalization requests
- Fixed `System.DateTime` casting errors in Azure blob upload processes
- Enhanced SAS URI renewal process with status checking loop for long-running uploads
- Updated `Expand-IntuneWin32AppCompressedFile` to use unique folder names preventing extraction conflicts
- Fixed `Test-IntuneWin32AppAssignment` to properly detect `#microsoft.graph.groupAssignmentTarget` assignment types
- Added throw statement in `Set-IntuneWin32App` catch block for proper error propagation
- Removed MSAL.PS from required modules list - now dynamically loaded only when needed (maintains backward compatibility)
- Enhanced `Connect-MSIntuneGraph` with improved error handling and dynamic MSAL.PS module loading
- Significantly improved automation and CI/CD pipeline support (tested extensively with GitHub Actions)
- Added verbose logging throughout retry operations for better debugging and monitoring
- Maximum retry delays capped at 60 seconds to prevent excessive wait times
- Transient error detection improved to handle API throttling and temporary service issues gracefully
- Added new architecture options: `arm64`, `x64x86`, `AllWithARM64` for comprehensive platform targeting
- Enhanced architecture targeting to align with Microsoft Intune's "Check operating system architecture" feature
- Improved architecture option naming for clarity: replaced confusing "All" option with explicit `x64x86`
- Added `Remove-IntuneWin32AppAssignmentAllUsers` function to selectively remove 'All Users' assignments from Win32 apps
- Added `Remove-IntuneWin32AppAssignmentAllDevices` function to selectively remove 'All Devices' assignments from Win32 apps
- New remove functions intelligently handle assignment removal across all intents (required, available, uninstall) with detailed intent-aware feedback
- Added ARM64 sample file demonstrating various architecture targeting scenarios
- **CRITICAL FIX**: Updated `Test-AccessToken` function to use 5-minute renewal threshold (down from 10 minutes) to prevent conflicts with minimum Access Token Lifetime policies in Entra ID
- Enhanced `Connect-MSIntuneGraph` function documentation with Windows Terminal compatibility guidance for authentication flows

## 1.4.4
- **BREAKING CHANGE**: Updated `New-IntuneWin32AppRequirementRule` function to support ARM64 architecture and switched to modern `allowedArchitectures` property by default
- **BREAKING CHANGE**: Updated `Connect-MSIntuneGraph` function to require explicit ClientID parameter - removed deprecated Microsoft Intune PowerShell enterprise application fallback
- Added new architecture options: `arm64`, `x64x86`, `AllWithARM64` for comprehensive platform targeting
- Enhanced architecture targeting to align with Microsoft Intune's "Check operating system architecture" feature
- Improved architecture option naming for clarity: replaced confusing "All" option with explicit `x64x86`
- Added `Remove-IntuneWin32AppAssignmentAllUsers` function to selectively remove 'All Users' assignments from Win32 apps
- Added `Remove-IntuneWin32AppAssignmentAllDevices` function to selectively remove 'All Devices' assignments from Win32 apps
- New remove functions intelligently handle assignment removal across all intents (required, available, uninstall) with detailed intent-aware feedback
- Added ARM64 sample file demonstrating various architecture targeting scenarios
- **CRITICAL FIX**: Updated `Test-AccessToken` function to use 5-minute renewal threshold (down from 10 minutes) to prevent conflicts with minimum Access Token Lifetime policies in Entra ID
- Enhanced `Connect-MSIntuneGraph` function documentation with Windows Terminal compatibility guidance for authentication flows

## 1.4.4
- Improved handling of empty object references in functions `Remove-IntuneWin32AppSupersedence` and `Remove-IntuneWin32AppDependency` functions that would render a null value to be added in the JSON construct instead of `[]`.
- Function `New-IntuneWin32AppPackage` function should now work better as for it's enforced output that it doesn't like when attempted to be hidden.
- Improved (hopefully) all aspects as to add and remove supersedence and dependencies.
- Improved return object property handling in `Get-IntuneWin32AppAssignment` function to include the same properties independent if using ID or Group parameter set. GroupID and GroupName properties are now also visible in the return object from the function when the ID parameter set is used and an assignment target type matches a group.
- Fixed a typo in the Test-AccessToken inner function of the `New-IntuneWin32AppDependency` function implementation where it was not encapsulating the function execution inside parentheses.
- Merged PR: ValidateRange works not as intended because the values are strings #142
- Fixed mentioned issue with `Test-AccessToken` function mentioned in #138

## 1.4.3
- Updated the New-IntuneWin32AppPackage function to work properly after the latest version of the IntuneWinAppUtil.exe was recently updated.

## 1.4.2
- Improved the output from the `Get-IntuneWin32AppAssignment` function with new properties such as FilterID, FilterType, DeliveryOptimizationPriority, Notifications, RestartSettings and InstallTimeSettings. Also improved function to generate same type of output instead of different per parameter set. Fixed issue #108 related to the same function.
- All function of this module that requires the usage of an access token, has been updated to make use of the `Test-AccessToken` function, to ensure an eligible token is present.
- Fixed issue #78 where `Get-IntuneWin32App` could not return more than the first 1000 objects, if more existed. This function now supports pagination.
- Added support for the new 'Installation time required' configuration option for Win32 applications, to the `Add-IntuneWin32App` function as a new parameter named `MaximumInstallationTimeInMinutes`.
- Added client certification authentication flow support in the `Connect-MSIntuneGraph` function.
- Added a new function named `Remove-IntuneWin32AppAssignmentGroup` function to support the removal of a group from assignment configuration of a specific Win32 app.
- Added Filter support for the `Add-IntuneWin32AppAssignmentAllDevices`, `Add-IntuneWin32AppAssignmentAllUsers` and `Add-IntuneWin32AppAssignmentGroup` functions.
- Improved `New-IntuneWin32AppPackage` function to better handle paths passed into the function, to use both -Path and -LiteralPath parameters to support wildcard characters. This fixes issue #113.
- Both functions `Remove-IntuneWin32AppDependency` and `Remove-IntuneWin32AppSupersedence` have been improved to only remove the actual relationships objects they originally were intended to remove, not all types as it would previously. This fixed what has been reported in #105.
- Private function `Get-IntuneWin32AppRelationshipsExistence` converted to public function and renamed to `Get-IntuneWin32AppRelationship`.

## 1.4.1
- Added a new function named `Test-AccessToken`, to assist when the current token is about to expire. This function will return `False` when the existing token is about to expire, within the give time frame defined in RenewalThresholdMinutes function parameter. Default is 10 minutes.
- `Add-IntuneWin32App` and `Set-IntuneWin32App` functions have been updated to support the new feature to allow of uninstallations of applications with an available assignment. At release of this version of the IntuneWin32App module, this feature has not publicly been announced by Microsoft, other than mentioned briefly in the 'In Development' documentation. However it has been available to be configured through Graph API for a couple of months at this point, hence this new functionality within the module is just for preparation of what's to come. The code of this module might have to be changed once the feature is publicly available and documented. Use this at your own risk.
- Fixed an issue with the Scope Tag functionality in the `Add-IntuneWin32App` function, where it would not return any Scope Tag id when authenticated as a user that is a member of a role in Intune (previously it only worked if the authenticated user was e.g. an Intune Administrator).
- Fixed issue #68 related to the `Add-IntuneWin32App` function when a RequirementRule object was not passed as parameter input, and the function would use default values.
- Added a new sample file called `9-Token refresh.ps1` to demonstrate how to handle token refresh scenarios in long running scripts.
- `New-IntuneWin32AppRequirementRule` function has been updated to support the newly added minimum operating system version of Windows 10 and 11. This change introduces a breaking change of existing scripts, since the new values that can be provided for the MinimumSupportedWindowsRelease parameter have been altered with a prefix of W10_ and W11_ to easier separate between the different operating system versions.

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
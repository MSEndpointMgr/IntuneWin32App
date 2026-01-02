---
applyTo: '**'
---

# IntuneWin32App Module - Context and Instructions

This document provides essential context about the IntuneWin32App PowerShell module for AI-assisted development.

## Module Overview

**Purpose**: PowerShell module for managing Win32 applications in Microsoft Intune via Microsoft Graph API

**Author**: Nickolaj Andersen (@NickolajA)

**Repository**: MSEndpointMgr/IntuneWin32App

**Current Version**: 1.5.0 (as of January 2026)

## Architecture

The module consists of two main function types:

### 1. Graph API Functions
Functions that directly interact with Microsoft Graph API:
- **App Management**: `Add-IntuneWin32App`, `Get-IntuneWin32App`, `Remove-IntuneWin32App`, `Set-IntuneWin32App`
- **Assignment Management**: `Add-IntuneWin32AppAssignment*`, `Remove-IntuneWin32AppAssignment*`, `Get-IntuneWin32AppAssignment`
- **Dependency Management**: `Add-IntuneWin32AppDependency`, `Remove-IntuneWin32AppDependency`, `Get-IntuneWin32AppDependency`, `Get-IntuneWin32AppRelationExistence`
- **Supersedence Management**: `Add-IntuneWin32AppSupersedence`, `Remove-IntuneWin32AppSupersedence`, `Get-IntuneWin32AppSupersedence`
- **Category Management**: `Get-IntuneWin32AppCategory`
- **Package Management**: `New-IntuneWin32AppPackage`, `Update-IntuneWin32AppPackageFile`, `Expand-IntuneWin32AppPackage`, `Get-IntuneWin32AppMetaData`
- **Authentication**: `Connect-MSIntuneGraph`, `Test-AccessToken`

### 2. Support Functions
Functions that create objects/components used by Graph API functions:
- `New-IntuneWin32AppDetectionRule*` (MSI, File, Registry, Script)
- `New-IntuneWin32AppRequirementRule*` (Architecture, File, Registry, Script)
- `New-IntuneWin32AppIcon`, `New-IntuneWin32AppReturnCode`
- `New-IntuneWin32AppDependency`, `New-IntuneWin32AppSupersedence`

## Key Technical Details

### Authentication (v1.5.0 - Breaking Change)
- **MSAL.PS Removed**: Module no longer depends on MSAL.PS
- **Custom OAuth Implementation**: Uses native OAuth 2.0 flows
- **Supported Flows**:
  - Interactive (Authorization Code with PKCE) - Default
  - DeviceCode (OAuth 2.0 Device Code flow)
  - ClientSecret (Client Credentials flow)
  - ClientCert - Not yet implemented
- **ClientID**: Mandatory parameter
- **Token Management**: 5-minute renewal threshold
- **Dynamic Port Assignment**: HTTP listener uses auto-assigned ports for localhost redirect (Interactive flow)

### Architecture Support
- **Modern Property**: `allowedArchitectures` (replaces `applicableArchitectures`)
- **Supported Architectures**: x64, x86, arm64, x64x86, AllWithARM64
- **Breaking Change**: ARM64 support added, legacy property removed

### Assignment Management
- **New Functions**: `Remove-IntuneWin32AppAssignmentAllUsers`, `Remove-IntuneWin32AppAssignmentAllDevices`
- **Intent-Aware**: Functions provide feedback based on assignment intent (required, available, uninstall)
- **Selective Removal**: Can remove specific assignment types without affecting others

## Module Structure

```
IntuneWin32App/
├── IntuneWin32App.psd1      # Module manifest
├── IntuneWin32App.psm1      # Main module file
├── Private/                  # Internal functions
│   ├── New-DelegatedAccessToken.ps1          # OAuth 2.0 Authorization Code + PKCE
│   ├── New-DeviceCodeAccessToken.ps1         # OAuth 2.0 Device Code flow
│   ├── New-ClientCredentialsAccessToken.ps1  # Client Credentials flow
│   └── ...
├── Public/                   # Exported functions
├── Development/              # Development scripts
├── Samples/                  # Example scripts
├── Tests/                    # Test suite (excluded from PSGallery)
└── README.md, LICENSE, etc.
```

## Test Suite Structure

The module has a comprehensive test suite located in `/Tests/` (excluded from PSGallery publishing):

### Test Suites:
1. **Lifecycle** (`Test-Win32AppLifecycle.ps1`): Complete workflow testing (package → create → update → remove)
2. **Assignments** (`Test-AssignmentManagement.ps1`): All assignment scenarios and management
3. **Components** (`Test-ModuleFunctions.ps1`): Graph API functions and support functions validation

### Test Runner:
- **Script**: `Invoke-IntuneWin32AppTests.ps1`
- **Usage**: `.\Invoke-IntuneWin32AppTests.ps1 -TestSuite All -ExportResults -Verbose`
- **Success Criteria**: 90%+ pass rate = ready for release

### Test Configuration:
- **Tenant**: cec1aa3f-dff2-48dd-8ddb-7c83e39f4547
- **Client**: d11ae3e7-b1aa-4b05-b769-4c6113b5263b (with delegated permissions)
- **Test App**: 7-Zip (7z2301-x64.msi)

## Recent Major Changes (v1.5.0)

### Breaking Changes:
1. **MSAL.PS Removed**: Module no longer requires or uses MSAL.PS - uses custom OAuth implementation
2. **ClientID Mandatory**: `Connect-MSIntuneGraph` requires explicit ClientID parameter
3. **Architecture Property**: Uses `allowedArchitectures` instead of `applicableArchitectures`
4. **ClientCert Flow**: Not yet implemented without MSAL.PS

### New Features:
1. **Native OAuth 2.0**: Authorization Code flow with PKCE (RFC 7636) implementation
2. **Device Code Flow**: Full support for device code authentication for non-interactive scenarios
3. **Dynamic Port Assignment**: HTTP listener automatically finds available ports
4. **PowerShell 5.1 Compatible**: Uses RNGCryptoServiceProvider for cryptographic operations
5. **Improved Error Handling**: OAuth-aware HTTP status codes (200, 400, 401, 403, 500, 503)
6. **Enhanced Diagnostics**: Verbose output for authentication troubleshooting

## Development Guidelines

### Code Patterns:
- **Authentication**: Always use `Connect-MSIntuneGraph` with explicit ClientID
- **Error Handling**: Use `Invoke-IntuneGraphRequest` for Graph API calls
- **Architecture**: Use modern `allowedArchitectures` property in requirement rules
- **Assignment Management**: Use specific removal functions for better UX

### Testing Before Release:
1. Run all test suites: `.\Invoke-IntuneWin32AppTests.ps1 -TestSuite All -ExportResults -Verbose`
2. Verify 90%+ pass rate
3. Test authentication in both PowerShell 5.1 and 7.x
4. Verify ARM64 architecture support works
5. Test on slow network connections (3-second response timeout)

### Publishing Exclusions:
- `/Tests/` folder (via .gitignore)
- Development artifacts (*.nupkg, *.local.ps1, etc.)

## PowerShell Coding Standards

### Code Formatting Rules:

1. **Hashtables and Custom Objects**: Never align equals signs in hashtables or custom objects
   - **Correct**: `@{ "key" = $value }`
   - **Incorrect**: `@{ "key"     = $value }`

2. **Write-Verbose Messages**: Never end verbose output with ellipsis (...)
   - **Correct**: `Write-Verbose -Message "Processing request"`
   - **Incorrect**: `Write-Verbose -Message "Processing request..."`

3. **Parameter Naming**: Always specify parameter names for cmdlets
   - **Correct**: `Write-Verbose -Message "text"`
   - **Incorrect**: `Write-Verbose "text"`

4. **Write-Host**: Never use `Write-Host` in any module code (Public or Private functions)
   - Always use `Write-Verbose` for diagnostic messages
   - Always use `Write-Warning` for warning messages
   - Always use `Write-Error` for error messages
   - Exception: None - Write-Host should not be used anywhere in the module

5. **Special Characters**: Avoid UTF-8 special characters in code and output
   - No: ✓, ✗, box-drawing characters, arrows, emojis
   - Use: ASCII characters only

6. **Punctuation in Output**: Avoid exclamation marks, question marks, and excessive punctuation in output messages
   - **Correct**: `Write-Output "Authentication successful"`
   - **Incorrect**: `Write-Output "Authentication successful!"`

7. **String Interpolation**: Always use `$()` syntax for variables inside strings
   - **Correct**: `"The value is $($variable)"`
   - **Incorrect**: `"The value is $variable"`
   - Applies to all variables including `$_`: use `$($_)` not `$_`

8. **PowerShell 5.1 Compatibility**: Ensure code works in both PowerShell 5.1 and 7.x
   - Use `RNGCryptoServiceProvider` instead of `RandomNumberGenerator.GetBytes()`
   - Test cryptographic operations in both versions

9. **Assembly Loading**: Always load required assemblies at the start of functions
   - Example: `Add-Type -AssemblyName System.Web` for HttpUtility
   - Example: `Add-Type -AssemblyName System.Net` for HttpListener

10. **Network Timing**: Allow sufficient time for network operations
   - HTTP response delivery: 3 seconds minimum before closing listeners
   - Token exchange: Use proper error handling with retry logic

## Common Issues and Solutions

### Authentication:
- **Problem**: ERR_CONNECTION_REFUSED during OAuth callback
- **Solution**: Ensure synchronous `GetContext()` with 3-second delay before stopping listener

- **Problem**: Interactive auth fails in Windows Terminal or non-browser environments
- **Solution**: Use DeviceCode flow (`Connect-MSIntuneGraph -TenantID <tenant> -ClientID <client> -DeviceCode`)

### Token Renewal:
- **Problem**: Token expires during long operations
- **Solution**: 5-minute threshold automatically handles renewal

### Architecture Support:
- **Problem**: Legacy `applicableArchitectures` not working
- **Solution**: Use `allowedArchitectures` property (breaking change in v1.4.5)

### PowerShell 5.1 Compatibility:
- **Problem**: `RandomNumberGenerator.GetBytes()` not available
- **Solution**: Use `RNGCryptoServiceProvider` with `GetBytes()` method

## Dependencies

### Required Modules:
- None - MSAL.PS dependency removed in v1.5.0

### Required Assemblies:
- System.Web - Query string parsing
- System.Net - HTTP listener for OAuth callbacks
- System.Security.Cryptography - PKCE implementation

### Azure AD Permissions (Delegated):
- DeviceManagementApps.ReadWrite.All
- DeviceManagementRBAC.Read.All

### Azure AD App Registration:
- Redirect URI: `http://localhost` (wildcard for dynamic ports)
- Public client: Yes (for Authorization Code flow with PKCE)

## File Locations and Naming

### Test Files Standard:
- Source: `C:\IntuneWin32App\Source\7-zip\7z2301-x64.msi`
- Output: `C:\IntuneWin32App\Output\`
- Icons: `C:\IntuneWin32App\Icons\7zip.png`

### Naming Conventions:
- Test apps: "*Test*" in display name
- Package files: `.intunewin` extension
- Result files: `*TestResults_YYYYMMDD_HHMMSS.json`

This context should provide sufficient background for understanding the module's structure, recent changes, and development approach in future sessions.
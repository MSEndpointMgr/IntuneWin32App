#
# Module manifest for module 'IntuneWin32App'
#
# Generated by: Nickolaj Andersen @NickolajA
#
# Generated on: 2020-01-04
#

@{
# Script module or binary module file associated with this manifest.
RootModule = 'IntuneWin32App.psm1'

# Version number of this module.
ModuleVersion = '1.3.5'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '2554f0a2-8047-49a1-bf6e-0108dc9263dc'

# Author of this module
Author = 'Nickolaj Andersen'

# Company or vendor of this module
CompanyName = 'MSEndpointMgr.com'

# Copyright statement for this module
Copyright = '(c) 2020 Nickolaj Andersen. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Provides a set of functions to manage Win32 apps in Microsoft Endpoint Manager (Intune).'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @("MSAL.PS")

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @("Add-IntuneWin32App",
                      "Add-IntuneWin32AppAssignment",
                      "Add-IntuneWin32AppAssignmentAllDevices",
                      "Add-IntuneWin32AppAssignmentAllUsers",
                      "Add-IntuneWin32AppAssignmentGroup",
                      "Add-IntuneWin32AppDependency",
                      "Add-IntuneWin32AppSupersedence"
                      "Connect-MSIntuneGraph",
                      "Expand-IntuneWin32AppPackage",
                      "Get-IntuneWin32App",
                      "Get-IntuneWin32AppAssignment",
                      "Get-IntuneWin32AppDependency",
                      "Get-IntuneWin32AppMetaData",
                      "Get-IntuneWin32AppSupersedence",
                      "Get-MSIMetaData",
                      "New-IntuneWin32AppDependency",
                      "New-IntuneWin32AppDetectionRule",
                      "New-IntuneWin32AppDetectionRuleFile",
                      "New-IntuneWin32AppDetectionRuleMSI",
                      "New-IntuneWin32AppDetectionRuleRegistry",
                      "New-IntuneWin32AppDetectionRuleScript",
                      "New-IntuneWin32AppIcon",
                      "New-IntuneWin32AppPackage",
                      "New-IntuneWin32AppRequirementRule",
                      "New-IntuneWin32AppRequirementRuleFile",
                      "New-IntuneWin32AppRequirementRuleRegistry",
                      "New-IntuneWin32AppRequirementRuleScript",
                      "New-IntuneWin32AppReturnCode",
                      "New-IntuneWin32AppSupersedence",
                      "Remove-IntuneWin32App",
                      "Remove-IntuneWin32AppAssignment",
                      "Remove-IntuneWin32AppDependency",
                      "Remove-IntuneWin32AppSupersedence",
                      "Update-IntuneWin32AppPackageFile"
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{
    PSData = @{
        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/MSEndpointMgr/IntuneWin32App'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}


function New-IntuneWin32AppRequirementRuleRegistry {
    <#
    .SYNOPSIS
        Create a new registry type of Requirement rule object to be used for the Add-IntuneWin32App function.

    .DESCRIPTION
        Create a new registry type of Requirement rule object to be used for the Add-IntuneWin32App function.

    .PARAMETER Existence
        Define that the requirement rule will be existence based, e.g. if a key or value exists or does not exist.

    .PARAMETER StringComparison
        Define that the requirement rule will be based on a specific string comparison.

    .PARAMETER IntegerComparison
        Define that the requirement rule will be based on an integer comparison.

    .PARAMETER VersionComparison
        Define that the requirement rule will be based on a version comparison.

    .PARAMETER KeyPath
        Specify a key path in the registry, e.g. 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft'.

    .PARAMETER ValueName
        Specify a registry value name, e.g. 'InstallVersion'.

    .PARAMETER Check32BitOn64System
        Decide whether to search in 32-bit registry on 64-bit environments.

    .PARAMETER DetectionType
        Specify the detection type of a key or value, if it either exists or doesn't exist.

    .PARAMETER StringComparisonOperator
        Specify the operator. Supported values are: equal, notEqual.

    .PARAMETER VersionComparisonOperator
        Specify the operator. Supported values are: equal, notEqual, greaterThanOrEqual, greaterThan, lessThanOrEqual or lessThan.

    .PARAMETER IntegerComparisonOperator
        Specify the operator. Supported values are: equal, notEqual, greaterThanOrEqual, greaterThan, lessThanOrEqual or lessThan.        

    .PARAMETER StringComparisonValue
        Specify a string object as the value to be used in a string comparison.

    .PARAMETER IntegerComparisonValue
        Specify an integer object as the value to be used in an integer comparison.

    .PARAMETER VersionComparisonValue
        Specify a string version object as the value, e.g. 1.0, 1.0.0 or 1.0.0.0 as input.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-04-29
        Updated:     2020-04-29

        Version history:
        1.0.0 - (2020-04-29) Function created
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, ParameterSetName = "Existence", HelpMessage = "Define that the requirement rule will be existence based, e.g. if a key or value exists or does not exist.")]
        [switch]$Existence,

        [parameter(Mandatory = $true, ParameterSetName = "StringComparison", HelpMessage = "Define that the requirement rule will be based on a specific string comparison.")]
        [switch]$StringComparison,

        [parameter(Mandatory = $true, ParameterSetName = "VersionComparison", HelpMessage = "Define that the requirement rule will be based on a version comparison.")]
        [switch]$VersionComparison,

        [parameter(Mandatory = $true, ParameterSetName = "IntegerComparison", HelpMessage = "Define that the requirement rule will be based on an integer comparison.")]
        [switch]$IntegerComparison,
        
        [parameter(Mandatory = $true, ParameterSetName = "Existence", HelpMessage = "Specify a key path in the registry, e.g. 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft'.")]
        [parameter(Mandatory = $true, ParameterSetName = "StringComparison")]
        [parameter(Mandatory = $true, ParameterSetName = "IntegerComparison")]
        [parameter(Mandatory = $true, ParameterSetName = "VersionComparison")]
        [ValidateNotNullOrEmpty()]
        [string]$KeyPath,

        [parameter(Mandatory = $false, ParameterSetName = "Existence", HelpMessage = "Specify a registry value name, e.g. 'InstallVersion'.")]
        [parameter(Mandatory = $false, ParameterSetName = "StringComparison")]
        [parameter(Mandatory = $false, ParameterSetName = "IntegerComparison")]
        [parameter(Mandatory = $false, ParameterSetName = "VersionComparison")]
        [ValidateNotNullOrEmpty()]
        [string]$ValueName = $null,

        [parameter(Mandatory = $false, ParameterSetName = "Existence", HelpMessage = "Decide whether to search in 32-bit registry on 64-bit environments.")]
        [parameter(Mandatory = $false, ParameterSetName = "StringComparison")]
        [parameter(Mandatory = $false, ParameterSetName = "IntegerComparison")]
        [parameter(Mandatory = $false, ParameterSetName = "VersionComparison")]
        [ValidateNotNullOrEmpty()]
        [bool]$Check32BitOn64System = $false,

        [parameter(Mandatory = $true, ParameterSetName = "Existence", HelpMessage = "Specify the detection type of a key or value, if it either exists or doesn't exist.")]
        [ValidateSet("exists", "doesNotExist")]
        [ValidateNotNullOrEmpty()]
        [string]$DetectionType,

        [parameter(Mandatory = $true, ParameterSetName = "StringComparison", HelpMessage = "Specify the operator. Supported values are: equal, notEqual.")]
        [ValidateSet("equal", "notEqual")]
        [ValidateNotNullOrEmpty()]
        [string]$StringComparisonOperator,

        [parameter(Mandatory = $true, ParameterSetName = "IntegerComparison", HelpMessage = "Specify the operator. Supported values are: equal, notEqual, greaterThanOrEqual, greaterThan, lessThanOrEqual, lessThan.")]
        [ValidateSet("equal", "notEqual", "greaterThanOrEqual", "greaterThan", "lessThanOrEqual", "lessThan")]
        [ValidateNotNullOrEmpty()]
        [string]$IntegerComparisonOperator,

        [parameter(Mandatory = $true, ParameterSetName = "VersionComparison", HelpMessage = "Specify the operator. Supported values are: equal, notEqual, greaterThanOrEqual, greaterThan, lessThanOrEqual, lessThan.")]
        [ValidateSet("equal", "notEqual", "greaterThanOrEqual", "greaterThan", "lessThanOrEqual", "lessThan")]
        [ValidateNotNullOrEmpty()]
        [string]$VersionComparisonOperator,        

        [parameter(Mandatory = $true, ParameterSetName = "StringComparison", HelpMessage = "Specify a string object as the value to be used in a string comparison.")]
        [ValidateNotNullOrEmpty()]
        [string]$StringComparisonValue,

        [parameter(Mandatory = $true, ParameterSetName = "IntegerComparison", HelpMessage = "Specify an integer object as the value to be used in an integer comparison.")]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^\d+$")]
        [string]$IntegerComparisonValue,

        [parameter(Mandatory = $true, ParameterSetName = "VersionComparison", HelpMessage = "Specify a string version object as the value, e.g. 1.0, 1.0.0 or 1.0.0.0 as input.")]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^(\d+(\.\d+){0,3})$")]
        [string]$VersionComparisonValue
    )
    Process {
        # Handle initial value for return
        $RequirementRuleRegistry = $null

        switch ($PSCmdlet.ParameterSetName) {
            "Existence" {
                # Construct ordered hash-table with least amount of required properties for default requirement rule
                $RequirementRuleRegistry = [ordered]@{
                    "@odata.type" = "#microsoft.graph.win32LobAppRegistryRequirement"
                    "operator" = "notConfigured"
                    "detectionValue" = $null
                    "check32BitOn64System" = $Check32BitOn64System
                    "keyPath" = $KeyPath
                    "valueName" = $ValueName
                    "detectionType" = $DetectionType
                }
            }
            "StringComparison" {
                # Construct ordered hash-table with least amount of required properties for default requirement rule
                $RequirementRuleRegistry = [ordered]@{
                    "@odata.type" = "#microsoft.graph.win32LobAppRegistryRequirement"
                    "operator" = $StringComparisonOperator
                    "detectionValue" = $StringComparisonValue
                    "check32BitOn64System" = $Check32BitOn64System
                    "keyPath" = $KeyPath
                    "valueName" = $ValueName
                    "detectionType" = "string"
                }
            }
            "IntegerComparison" {
                # Construct ordered hash-table with least amount of required properties for default requirement rule
                $RequirementRuleRegistry = [ordered]@{
                    "@odata.type" = "#microsoft.graph.win32LobAppRegistryRequirement"
                    "operator" = $IntegerComparisonOperator
                    "detectionValue" = $IntegerComparisonValue
                    "check32BitOn64System" = $Check32BitOn64System
                    "keyPath" = $KeyPath
                    "valueName" = $ValueName
                    "detectionType" = "integer"
                }
            }            
            "VersionComparison" {
                # Construct ordered hash-table with least amount of required properties for default requirement rule
                $RequirementRuleRegistry = [ordered]@{
                    "@odata.type" = "#microsoft.graph.win32LobAppRegistryRequirement"
                    "operator" = $VersionComparisonOperator
                    "detectionValue" = $VersionComparisonValue
                    "check32BitOn64System" = $Check32BitOn64System
                    "keyPath" = $KeyPath
                    "valueName" = $ValueName
                    "detectionType" = "version"
                }
            }
        }

        # Handle return value with constructed requirement rule for file
        return $RequirementRuleRegistry
    }
}
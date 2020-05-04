function New-IntuneWin32AppRequirementRuleRegistry {
    <#
    .SYNOPSIS
        Create a new Requirement rule object to be used for the Add-IntuneWin32App function.

    .DESCRIPTION
        Create a new Requirement rule object to be used for the Add-IntuneWin32App function.

    .PARAMETER Existence
        Define that the detection rule will be existence based, e.g. if a key or value exists or does not exist.

    .PARAMETER DateModified
        

    .PARAMETER DateCreated
        

    .PARAMETER Version
        

    .PARAMETER Size
        

    .PARAMETER KeyPath
        Specify a key path in the registry, e.g. 'HKLM\SOFTWARE\Microsoft'.

    .PARAMETER ValueName
        Specify a value name, e.g. 'InstallVersion'.

    .PARAMETER Check32BitOn64System
        Decide whether to search in 32-bit registry on 64-bit environments.

    .PARAMETER DetectionType
        Specify the detection type of an file or folder, if it either exists or doesn't exist.

    .PARAMETER Operator
        Specify the operator. Supported values are: notConfigured, equal, notEqual, greaterThanOrEqual, greaterThan, lessThanOrEqual or lessThan.

    .PARAMETER DateValue
        Specify a datetime object as the value.

    .PARAMETER VersionValue
        Specify a string version object as the value, e.g. 1.0, 1.0.0 or 1.0.0.0 as input.

    .PARAMETER SizeInMBValue
        Specify the file size in MB as a positive integer or 0.

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
        [parameter(Mandatory = $true, ParameterSetName = "Existence", HelpMessage = "Define that the detection rule will be existence based, e.g. if a key or value exists or does not exist.")]
        [switch]$Existence,

        [parameter(Mandatory = $true, ParameterSetName = "DateModified", HelpMessage = "Define that the detection rule will be based on a file or folders date modified value.")]
        [switch]$DateModified,

        [parameter(Mandatory = $true, ParameterSetName = "DateCreated", HelpMessage = "Define that the detection rule will be based on when a file or folder was created.")]
        [switch]$DateCreated,

        [parameter(Mandatory = $true, ParameterSetName = "Version", HelpMessage = "Define that the detection rule will be based on the file version number specified as value.")]
        [switch]$Version,

        [parameter(Mandatory = $true, ParameterSetName = "Size", HelpMessage = "Define that the detection rule will be based on the file size in MB specified as 0 or a positive integer value.")]
        [switch]$Size,
        
        [parameter(Mandatory = $true, ParameterSetName = "Existence", HelpMessage = "Specify a key path in the registry, e.g. 'HKLM\SOFTWARE\Microsoft'.")]
        [parameter(Mandatory = $true, ParameterSetName = "Size")]
        [ValidateNotNullOrEmpty()]
        [string]$KeyPath,

        [parameter(Mandatory = $false, ParameterSetName = "Existence", HelpMessage = "Specify a value name, e.g. 'InstallVersion'.")]
        [parameter(Mandatory = $false, ParameterSetName = "Size")]
        [ValidateNotNullOrEmpty()]
        [string]$ValueName = $null,

        [parameter(Mandatory = $false, ParameterSetName = "Existence", HelpMessage = "Decide whether to search in 32-bit registry on 64-bit environments.")]
        [parameter(Mandatory = $false, ParameterSetName = "Size")]
        [ValidateNotNullOrEmpty()]
        [bool]$Check32BitOn64System = $false,

        [parameter(Mandatory = $true, ParameterSetName = "Existence", HelpMessage = "Specify the detection type of a key or value, if it either exists or doesn't exist.")]
        [ValidateSet("exists", "doesNotExist")]
        [ValidateNotNullOrEmpty()]
        [string]$DetectionType,

        [parameter(Mandatory = $true, ParameterSetName = "DateModified", HelpMessage = "Specify the operator. Supported values are: notConfigured, equal, notEqual, greaterThanOrEqual, greaterThan, lessThanOrEqual or lessThan.")]
        [parameter(Mandatory = $true, ParameterSetName = "Size")]
        [ValidateSet("equal", "notEqual", "greaterThanOrEqual", "greaterThan", "lessThanOrEqual", "lessThan")]
        [ValidateNotNullOrEmpty()]
        [string]$Operator
    )
    Process {
        switch ($PSCmdlet.ParameterSetName) {
            "Existence" {
                # Construct ordered hash-table with least amount of required properties for default requirement rule
                $RequirementRuleRegistry = [ordered]@{
                    "@odata.type" = "#microsoft.graph.win32LobAppRegistryRequirement"
                    "operator" = "notConfigured"
                    "detectionValue" = $null
                    "check32BitOn64System" = $Check32BitOn64System
                    "keyPath" = [regex]::Escape($KeyPath)
                    "valueName" = $ValueName
                    "detectionType" = $DetectionType
                }
            }
            #
            "Size" {
                # Construct ordered hash-table with least amount of required properties for default requirement rule
                $RequirementRuleRegistry = [ordered]@{
                    "@odata.type" = "#microsoft.graph.win32LobAppFileSystemRequirement"
                    "operator" = $Operator
                    "detectionValue" = $SizeInMBValue
                    "path" = [regex]::Escape($Path)
                    "fileOrFolderName" = $FileOrFolder
                    "check32BitOn64System" = $Check32BitOn64System
                    "detectionType" = "sizeInMB"
                }
            }
        }

        # Handle return value with constructed requirement rule for file
        return $RequirementRuleRegistry
    }
}
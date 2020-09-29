function New-IntuneWin32AppDetectionRuleFile {
    <#
    .SYNOPSIS
        Create a new file based detection rule object to be used for the Add-IntuneWin32App function.

    .DESCRIPTION
        Create a new file based detection rule object to be used for the Add-IntuneWin32App function.

    .PARAMETER Existence
        Define that the detection rule will be existence based, e.g. if a file or folder exists or does not exist.

    .PARAMETER DateModified
        Define that the detection rule will be based on a file or folders date modified value.

    .PARAMETER DateCreated
        Define that the detection rule will be based on when a file or folder was created.

    .PARAMETER Version
        Define that the detection rule will be based on the file version number specified as value.

    .PARAMETER Size
        Define that the detection rule will be based on the file size in MB specified as 0 or a positive integer value.

    .PARAMETER Path
        Specify a path that will be combined with what's passed for the FileOrFolder parameter, e.g. C:\Windows\Temp.

    .PARAMETER FileOrFolder
        Specify a file or folder name that will be combined with what's passed for the Path parameter, e.g. File.exe.

    .PARAMETER Check32BitOn64System
        Decide whether environment variables should be expanded in 32-bit context on 64-bit environments.

    .PARAMETER DetectionType
        Specify the detection type of an file or folder, if it either exists or doesn't exist.

    .PARAMETER Operator
        Specify the operator. Supported values are: equal, notEqual, greaterThanOrEqual, greaterThan, lessThanOrEqual or lessThan.

    .PARAMETER DateTimeValue
        Specify a datetime object as the value.

    .PARAMETER VersionValue
        Specify a string version object as the value, e.g. 1.0, 1.0.0 or 1.0.0.0 as input.

    .PARAMETER SizeInMBValue
        Specify the file size in MB as a positive integer or 0.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-09-17
        Updated:     2020-09-17

        Version history:
        1.0.0 - (2020-09-17) Function created
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, ParameterSetName = "Existence", HelpMessage = "Define that the detection rule will be existence based, e.g. if a file or folder exists or does not exist.")]
        [switch]$Existence,

        [parameter(Mandatory = $true, ParameterSetName = "DateModified", HelpMessage = "Define that the detection rule will be based on a file or folders date modified value.")]
        [switch]$DateModified,

        [parameter(Mandatory = $true, ParameterSetName = "DateCreated", HelpMessage = "Define that the detection rule will be based on when a file or folder was created.")]
        [switch]$DateCreated,

        [parameter(Mandatory = $true, ParameterSetName = "Version", HelpMessage = "Define that the detection rule will be based on the file version number specified as value.")]
        [switch]$Version,

        [parameter(Mandatory = $true, ParameterSetName = "Size", HelpMessage = "Define that the detection rule will be based on the file size in MB specified as 0 or a positive integer value.")]
        [switch]$Size,
        
        [parameter(Mandatory = $true, ParameterSetName = "Existence", HelpMessage = "Specify a path that will be combined with what's passed for the FileOrFolder parameter, e.g. C:\Windows\Temp.")]
        [parameter(Mandatory = $true, ParameterSetName = "DateModified")]
        [parameter(Mandatory = $true, ParameterSetName = "DateCreated")]
        [parameter(Mandatory = $true, ParameterSetName = "Version")]
        [parameter(Mandatory = $true, ParameterSetName = "Size")]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [parameter(Mandatory = $true, ParameterSetName = "Existence", HelpMessage = "Specify a file or folder name that will be combined with what's passed for the Path parameter, e.g. File.exe.")]
        [parameter(Mandatory = $true, ParameterSetName = "DateModified")]
        [parameter(Mandatory = $true, ParameterSetName = "DateCreated")]
        [parameter(Mandatory = $true, ParameterSetName = "Version")]
        [parameter(Mandatory = $true, ParameterSetName = "Size")]
        [ValidateNotNullOrEmpty()]
        [string]$FileOrFolder,

        [parameter(Mandatory = $false, ParameterSetName = "Existence", HelpMessage = "Decide whether environment variables should be expanded in 32-bit context on 64-bit environments.")]
        [parameter(Mandatory = $false, ParameterSetName = "DateModified")]
        [parameter(Mandatory = $false, ParameterSetName = "DateCreated")]
        [parameter(Mandatory = $false, ParameterSetName = "Version")]
        [parameter(Mandatory = $false, ParameterSetName = "Size")]
        [ValidateNotNullOrEmpty()]
        [bool]$Check32BitOn64System = $false,

        [parameter(Mandatory = $true, ParameterSetName = "Existence", HelpMessage = "Specify the detection type of an file or folder, if it either exists or doesn't exist.")]
        [ValidateSet("exists", "doesNotExist")]
        [ValidateNotNullOrEmpty()]
        [string]$DetectionType,

        [parameter(Mandatory = $true, ParameterSetName = "DateModified", HelpMessage = "Specify the operator. Supported values are: equal, notEqual, greaterThanOrEqual, greaterThan, lessThanOrEqual or lessThan.")]
        [parameter(Mandatory = $true, ParameterSetName = "DateCreated")]
        [parameter(Mandatory = $true, ParameterSetName = "Version")]
        [parameter(Mandatory = $true, ParameterSetName = "Size")]
        [ValidateSet("equal", "notEqual", "greaterThanOrEqual", "greaterThan", "lessThanOrEqual", "lessThan")]
        [ValidateNotNullOrEmpty()]
        [string]$Operator,

        [parameter(Mandatory = $true, ParameterSetName = "DateModified", HelpMessage = "Specify a datetime object as the value.")]
        [parameter(Mandatory = $true, ParameterSetName = "DateCreated")]
        [ValidateNotNullOrEmpty()]
        [datetime]$DateTimeValue,

        [parameter(Mandatory = $true, ParameterSetName = "Version", HelpMessage = "Specify a string version object as the value, e.g. 1.0, 1.0.0 or 1.0.0.0 as input.")]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^(\d+(\.\d+){0,3})$")]
        [string]$VersionValue,

        [parameter(Mandatory = $true, ParameterSetName = "Size", HelpMessage = "Specify the file size in MB as a positive integer or 0.")]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^\d+$")]
        [string]$SizeInMBValue
    )
    Process {
        # Handle initial value for return
        $DetectionRuleFile = $null

        switch ($PSCmdlet.ParameterSetName) {
            "Existence" {
                # Construct ordered hash-table with least amount of required properties for default detection rule
                $DetectionRuleFile = [ordered]@{
                    "@odata.type" = "#microsoft.graph.win32LobAppFileSystemDetection"
                    "operator" = "notConfigured"
                    "detectionValue" = $null
                    "path" = $Path
                    "fileOrFolderName" = $FileOrFolder
                    "check32BitOn64System" = $Check32BitOn64System
                    "detectionType" = $DetectionType
                }
            }
            "DateModified" {
                # Convert input datetime object to ISO 8601 string
                $DateValueString = ConvertTo-JSONDate -InputObject $DateTimeValue

                # Construct ordered hash-table with least amount of required properties for default detection rule
                $DetectionRuleFile = [ordered]@{
                    "@odata.type" = "#microsoft.graph.win32LobAppFileSystemDetection"
                    "operator" = $Operator
                    "detectionValue" = $DateValueString
                    "path" = $Path
                    "fileOrFolderName" = $FileOrFolder
                    "check32BitOn64System" = $Check32BitOn64System
                    "detectionType" = "modifiedDate"
                }
            }
            "DateCreated" {
                # Convert input datetime object to ISO 8601 string
                $DateValueString = ConvertTo-JSONDate -InputObject $DateTimeValue

                # Construct ordered hash-table with least amount of required properties for default detection rule
                $DetectionRuleFile = [ordered]@{
                    "@odata.type" = "#microsoft.graph.win32LobAppFileSystemDetection"
                    "operator" = $Operator
                    "detectionValue" = $DateValueString
                    "path" = $Path
                    "fileOrFolderName" = $FileOrFolder
                    "check32BitOn64System" = $Check32BitOn64System
                    "detectionType" = "createdDate"
                }
            }
            "Version" {
                # Construct ordered hash-table with least amount of required properties for default detection rule
                $DetectionRuleFile = [ordered]@{
                    "@odata.type" = "#microsoft.graph.win32LobAppFileSystemDetection"
                    "operator" = $Operator
                    "detectionValue" = $VersionValue
                    "path" = $Path
                    "fileOrFolderName" = $FileOrFolder
                    "check32BitOn64System" = $Check32BitOn64System
                    "detectionType" = "version"
                }
            }
            "Size" {
                # Construct ordered hash-table with least amount of required properties for default detection rule
                $DetectionRuleFile = [ordered]@{
                    "@odata.type" = "#microsoft.graph.win32LobAppFileSystemDetection"
                    "operator" = $Operator
                    "detectionValue" = $SizeInMBValue
                    "path" = $Path
                    "fileOrFolderName" = $FileOrFolder
                    "check32BitOn64System" = $Check32BitOn64System
                    "detectionType" = "sizeInMB"
                }
            }
        }

        # Handle return value with constructed detection rule for file
        return $DetectionRuleFile
    }
}
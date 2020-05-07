function New-IntuneWin32AppRequirementRuleScript {
    <#
    .SYNOPSIS
        Create a new script type of Requirement rule object to be used for the Add-IntuneWin32App function.

    .DESCRIPTION
        Create a new script type of Requirement rule object to be used for the Add-IntuneWin32App function.

    .PARAMETER 
        

    .PARAMETER 
        

    .PARAMETER 
        

    .PARAMETER 
        

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
        [parameter(Mandatory = $true, HelpMessage = "Specify the full path to the PowerShell script file, e.g. 'C:\Scripts\Rule.ps1'.")]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptFile,
        
        [parameter(Mandatory = $true, HelpMessage = "Specify the output data type used when determining a detection match requirement. Supported values: string, integer, dateTime,")]
        [ValidateSet("string", "integer", "dateTime")]
        [ValidateNotNullOrEmpty()]
        [string]$OutputDataType,

        [parameter(Mandatory = $false, HelpMessage = "Set as True to run as a 32-bit process in a 64-bit environment.")]
        [ValidateNotNullOrEmpty()]
        [bool]$RunAs32BitOn64System = $false,

        [parameter(Mandatory = $true, ParameterSetName = "IntegerComparison", HelpMessage = "Specify the operator. Supported values are: equal, notEqual, greaterThanOrEqual, greaterThan, lessThanOrEqual, lessThan.")]
        [ValidateSet("equal", "notEqual", "greaterThanOrEqual", "greaterThan", "lessThanOrEqual", "lessThan")]
        [ValidateNotNullOrEmpty()]
        [string]$IntegerComparisonOperator
    )
    Process {
        # Handle initial value for return
        $RequirementRuleScript = $null

        # Detect if passed script file exists
        if (Test-Path -Path $ScriptFile) {
            # Convert script file contents to base64 string
            $ScriptContent = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$($ScriptFile)"))

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
            }
        }

        # Handle return value with constructed requirement rule for file
        return $RequirementRuleRegistry
    }
}
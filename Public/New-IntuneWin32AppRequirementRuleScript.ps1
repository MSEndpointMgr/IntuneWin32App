function New-IntuneWin32AppRequirementRuleScript {
    <#
    .SYNOPSIS
        Create a new script type of Requirement rule object to be used for the Add-IntuneWin32App function.

    .DESCRIPTION
        Create a new script type of Requirement rule object to be used for the Add-IntuneWin32App function.

    .PARAMETER StringOutputDataType
        Select output data type as a string, used when determining a detection match requirement.

    .PARAMETER IntegerOutputDataType
        Select output data type as a integer, used when determining a detection match requirement.

    .PARAMETER BooleanOutputDataType
        Select output data type as a boolean, used when determining a detection match requirement.

    .PARAMETER DateTimeOutputDataType
        Select output data type as a date time, used when determining a detection match requirement.

    .PARAMETER FloatOutputDataType
        Select output data type as a floating point, used when determining a detection match requirement.

    .PARAMETER VersionOutputDataType
        Select output data type as a version, used when determining a detection match requirement.

    .PARAMETER ScriptFile
        Specify the full path to the PowerShell script file, e.g. 'C:\Scripts\Rule.ps1'.

    .PARAMETER ScriptContext
        Specify to either run the script in the local system context or with signed in user context.

    .PARAMETER StringComparisonOperator
        Specify the operator. Supported values are: equal, notEqual.

    .PARAMETER IntegerComparisonOperator
        Specify the operator. Supported values are: equal, notEqual, greaterThanOrEqual, greaterThan, lessThanOrEqual, lessThan.

    .PARAMETER BooleanComparisonOperator
        Specify the operator. Supported values are: equal, notEqual.

    .PARAMETER DateTimeComparisonOperator
        Specify the operator. Supported values are: equal, notEqual, greaterThanOrEqual, greaterThan, lessThanOrEqual, lessThan.
    
    .PARAMETER FloatComparisonOperator
        Specify the operator. Supported values are: equal, notEqual, greaterThanOrEqual, greaterThan, lessThanOrEqual, lessThan.

    .PARAMETER VersionComparisonOperator
        Specify the operator. Supported values are: equal, notEqual, greaterThanOrEqual, greaterThan, lessThanOrEqual, lessThan.

    .PARAMETER StringValue
        Specify the detection match value.

    .PARAMETER IntegerValue
        Specify the detection match value.

    .PARAMETER BooleanValue
        Specify the detection match value.

    .PARAMETER DateTimeValue
        Specify the detection match value.

    .PARAMETER FloatValue
        Specify the detection match value.

    .PARAMETER VersionValue
        Specify the detection match value.

    .PARAMETER RunAs32BitOn64System
        Set as True to run as a 32-bit process in a 64-bit environment.

    .PARAMETER EnforceSignatureCheck
        Set as True to verify that the script executed is signed by a trusted publisher.
                
    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-04-29
        Updated:     2022-09-02

        Version history:
        1.0.0 - (2020-04-29) Function created
        1.0.1 - (2021-08-31) Fixed an issue when using a non-UTF encoded multi-line script file
        1.0.2 - (2022-09-02) Fixed GitHub reported issue #41 (https://github.com/MSEndpointMgr/IntuneWin32App/issues/41)
                             Fixed issue with wrong variables used for the Version based part for #microsoft.graph.win32LobAppPowerShellScriptRequirement
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, ParameterSetName = "String", HelpMessage = "Select output data type as a string, used when determining a detection match requirement.")]
        [switch]$StringOutputDataType,

        [parameter(Mandatory = $true, ParameterSetName = "Integer", HelpMessage = "Select output data type as a integer, used when determining a detection match requirement.")]
        [switch]$IntegerOutputDataType,

        [parameter(Mandatory = $true, ParameterSetName = "Boolean", HelpMessage = "Select output data type as a boolean, used when determining a detection match requirement.")]
        [switch]$BooleanOutputDataType,

        [parameter(Mandatory = $true, ParameterSetName = "DateTime", HelpMessage = "Select output data type as a date time, used when determining a detection match requirement.")]
        [switch]$DateTimeOutputDataType,

        [parameter(Mandatory = $true, ParameterSetName = "Float", HelpMessage = "Select output data type as a floating point, used when determining a detection match requirement.")]
        [switch]$FloatOutputDataType,

        [parameter(Mandatory = $true, ParameterSetName = "Version", HelpMessage = "Select output data type as a version, used when determining a detection match requirement.")]
        [switch]$VersionOutputDataType,

        [parameter(Mandatory = $true, ParameterSetName = "String", HelpMessage = "Specify the full path to the PowerShell script file, e.g. 'C:\Scripts\Rule.ps1'.")]
        [parameter(Mandatory = $true, ParameterSetName = "Integer")]
        [parameter(Mandatory = $true, ParameterSetName = "Boolean")]
        [parameter(Mandatory = $true, ParameterSetName = "DateTime")]
        [parameter(Mandatory = $true, ParameterSetName = "Float")]
        [parameter(Mandatory = $true, ParameterSetName = "Version")]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptFile,

        [parameter(Mandatory = $true, ParameterSetName = "String", HelpMessage = "Specify to either run the script in the local system context or with signed in user context.")]
        [parameter(Mandatory = $true, ParameterSetName = "Integer")]
        [parameter(Mandatory = $true, ParameterSetName = "Boolean")]
        [parameter(Mandatory = $true, ParameterSetName = "DateTime")]
        [parameter(Mandatory = $true, ParameterSetName = "Float")]
        [parameter(Mandatory = $true, ParameterSetName = "Version")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("system", "user")]
        [string]$ScriptContext,
               
        [parameter(Mandatory = $true, ParameterSetName = "String", HelpMessage = "Specify the operator. Supported values are: equal, notEqual.")]
        [ValidateSet("equal", "notEqual")]
        [ValidateNotNullOrEmpty()]
        [string]$StringComparisonOperator,

        [parameter(Mandatory = $true, ParameterSetName = "Integer", HelpMessage = "Specify the operator. Supported values are: equal, notEqual, greaterThanOrEqual, greaterThan, lessThanOrEqual, lessThan.")]
        [ValidateSet("equal", "notEqual", "greaterThanOrEqual", "greaterThan", "lessThanOrEqual", "lessThan")]
        [ValidateNotNullOrEmpty()]
        [string]$IntegerComparisonOperator,

        [parameter(Mandatory = $true, ParameterSetName = "Boolean", HelpMessage = "Specify the operator. Supported values are: equal, notEqual.")]
        [ValidateSet("equal", "notEqual")]
        [ValidateNotNullOrEmpty()]
        [string]$BooleanComparisonOperator,

        [parameter(Mandatory = $true, ParameterSetName = "DateTime", HelpMessage = "Specify the operator. Supported values are: equal, notEqual, greaterThanOrEqual, greaterThan, lessThanOrEqual, lessThan.")]
        [ValidateSet("equal", "notEqual", "greaterThanOrEqual", "greaterThan", "lessThanOrEqual", "lessThan")]
        [ValidateNotNullOrEmpty()]
        [string]$DateTimeComparisonOperator,

        [parameter(Mandatory = $true, ParameterSetName = "Float", HelpMessage = "Specify the operator. Supported values are: equal, notEqual, greaterThanOrEqual, greaterThan, lessThanOrEqual, lessThan.")]
        [ValidateSet("equal", "notEqual", "greaterThanOrEqual", "greaterThan", "lessThanOrEqual", "lessThan")]
        [ValidateNotNullOrEmpty()]
        [string]$FloatComparisonOperator,

        [parameter(Mandatory = $true, ParameterSetName = "Version", HelpMessage = "Specify the operator. Supported values are: equal, notEqual, greaterThanOrEqual, greaterThan, lessThanOrEqual, lessThan.")]
        [ValidateSet("equal", "notEqual", "greaterThanOrEqual", "greaterThan", "lessThanOrEqual", "lessThan")]
        [ValidateNotNullOrEmpty()]
        [string]$VersionComparisonOperator,

        [parameter(Mandatory = $true, ParameterSetName = "String", HelpMessage = "Specify the detection match value.")]
        [ValidateNotNullOrEmpty()]
        [string]$StringValue,

        [parameter(Mandatory = $true, ParameterSetName = "Integer", HelpMessage = "Specify the detection match value.")]
        [ValidateNotNullOrEmpty()]
        [string]$IntegerValue,

        [parameter(Mandatory = $true, ParameterSetName = "Boolean", HelpMessage = "Specify the detection match value.")]
        [ValidateNotNullOrEmpty()]
        [bool]$BooleanValue,

        [parameter(Mandatory = $true, ParameterSetName = "DateTime", HelpMessage = "Specify the detection match value.")]
        [ValidateNotNullOrEmpty()]
        [datetime]$DateTimeValue,

        [parameter(Mandatory = $true, ParameterSetName = "Float", HelpMessage = "Specify the detection match value.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("^((\+|-)?(0|([1-9][0-9]*))(\.[0-9]+)?)$")]
        [string]$FloatValue,

        [parameter(Mandatory = $true, ParameterSetName = "Version", HelpMessage = "Specify the detection match value.")]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^(\d+(\.\d+){0,3})$")]
        [string]$VersionValue,

        [parameter(Mandatory = $false, ParameterSetName = "String", HelpMessage = "Set as True to run as a 32-bit process in a 64-bit environment.")]
        [parameter(Mandatory = $false, ParameterSetName = "Integer")]
        [parameter(Mandatory = $false, ParameterSetName = "Boolean")]
        [parameter(Mandatory = $false, ParameterSetName = "DateTime")]
        [parameter(Mandatory = $false, ParameterSetName = "Float")]
        [parameter(Mandatory = $false, ParameterSetName = "Version")]        
        [ValidateNotNullOrEmpty()]
        [bool]$RunAs32BitOn64System = $false,

        [parameter(Mandatory = $false, ParameterSetName = "String", HelpMessage = "Set as True to verify that the script executed is signed by a trusted publisher.")]
        [parameter(Mandatory = $false, ParameterSetName = "Integer")]
        [parameter(Mandatory = $false, ParameterSetName = "Boolean")]
        [parameter(Mandatory = $false, ParameterSetName = "DateTime")]
        [parameter(Mandatory = $false, ParameterSetName = "Float")]
        [parameter(Mandatory = $false, ParameterSetName = "Version")]
        [ValidateNotNullOrEmpty()]
        [bool]$EnforceSignatureCheck = $false
    )
    Process {
        # Handle initial value for return
        $RequirementRuleScript = $null

        # Detect if passed script file exists
        Write-Verbose -Message "Attempting to locate given script file in provided path: $($ScriptFile)"
        if (Test-Path -Path $ScriptFile) {
            # Get script file name from provided path
            $ScriptFileName = [System.IO.Path]::GetFileName("$($ScriptFile)")

            # Convert script file contents to base64 string
            $ScriptContent = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((Get-Content -Path "$($ScriptFile)" -Raw -Encoding UTF8)))

            switch ($PSCmdlet.ParameterSetName) {
                "String" {
                    # Construct ordered hash-table with least amount of required properties for default requirement rule
                    $RequirementRuleScript = [ordered]@{
                        "@odata.type" = "#microsoft.graph.win32LobAppPowerShellScriptRequirement"
                        "operator" = $StringComparisonOperator
                        "detectionValue" = $StringValue
                        "displayName" = $ScriptFileName
                        "enforceSignatureCheck" = $EnforceSignatureCheck
                        "runAs32Bit" = $RunAs32BitOn64System
                        "runAsAccount" = $ScriptContext
                        "scriptContent" = $ScriptContent
                        "detectionType" = "string"
                    }
                }
                "Integer" {
                    # Construct ordered hash-table with least amount of required properties for default requirement rule
                    $RequirementRuleScript = [ordered]@{
                        "@odata.type" = "#microsoft.graph.win32LobAppPowerShellScriptRequirement"
                        "operator" = $IntegerComparisonOperator
                        "detectionValue" = $IntegerValue
                        "displayName" = $ScriptFileName
                        "enforceSignatureCheck" = $EnforceSignatureCheck
                        "runAs32Bit" = $RunAs32BitOn64System
                        "runAsAccount" = $ScriptContext
                        "scriptContent" = $ScriptContent
                        "detectionType" = "integer"
                    }
                }
                "Boolean" {
                    # Construct ordered hash-table with least amount of required properties for default requirement rule
                    $RequirementRuleScript = [ordered]@{
                        "@odata.type" = "#microsoft.graph.win32LobAppPowerShellScriptRequirement"
                        "operator" = $BooleanComparisonOperator
                        "detectionValue" = $BooleanValue
                        "displayName" = $ScriptFileName
                        "enforceSignatureCheck" = $EnforceSignatureCheck
                        "runAs32Bit" = $RunAs32BitOn64System
                        "runAsAccount" = $ScriptContext
                        "scriptContent" = $ScriptContent
                        "detectionType" = "boolean"
                    }
                }
                "DateTime" {
                    # Convert input datetime object to ISO 8601 string
                    $DateValueString = ConvertTo-JSONDate -InputObject $DateTimeValue
                    
                    # Construct ordered hash-table with least amount of required properties for default requirement rule
                    $RequirementRuleScript = [ordered]@{
                        "@odata.type" = "#microsoft.graph.win32LobAppPowerShellScriptRequirement"
                        "operator" = $DateTimeComparisonOperator
                        "detectionValue" = $DateValueString
                        "displayName" = $ScriptFileName
                        "enforceSignatureCheck" = $EnforceSignatureCheck
                        "runAs32Bit" = $RunAs32BitOn64System
                        "runAsAccount" = $ScriptContext
                        "scriptContent" = $ScriptContent
                        "detectionType" = "dateTime"
                    }
                }
                "Float" {
                    # Construct ordered hash-table with least amount of required properties for default requirement rule
                    $RequirementRuleScript = [ordered]@{
                        "@odata.type" = "#microsoft.graph.win32LobAppPowerShellScriptRequirement"
                        "operator" = $FloatComparisonOperator
                        "detectionValue" = $FloatValue
                        "displayName" = $ScriptFileName
                        "enforceSignatureCheck" = $EnforceSignatureCheck
                        "runAs32Bit" = $RunAs32BitOn64System
                        "runAsAccount" = $ScriptContext
                        "scriptContent" = $ScriptContent
                        "detectionType" = "float"
                    }
                }
                "Version" {
                    # Construct ordered hash-table with least amount of required properties for default requirement rule
                    $RequirementRuleScript = [ordered]@{
                        "@odata.type" = "#microsoft.graph.win32LobAppPowerShellScriptRequirement"
                        "operator" = $VersionComparisonOperator
                        "detectionValue" = $VersionValue
                        "displayName" = $ScriptFileName
                        "enforceSignatureCheck" = $EnforceSignatureCheck
                        "runAs32Bit" = $RunAs32BitOn64System
                        "runAsAccount" = $ScriptContext
                        "scriptContent" = $ScriptContent
                        "detectionType" = "version"
                    }
                }
            }
        }
        else {
            Write-Warning -Message "Unable to detect specified script file in given path: $($ScriptFile)"
        }

        # Handle return value with constructed requirement rule for file
        return $RequirementRuleScript
    }
}
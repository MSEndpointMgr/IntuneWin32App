function New-IntuneWin32AppDetectionRuleMSI {
    <#
    .SYNOPSIS
        Create a new MSI based detection rule object to be used for the Add-IntuneWin32App function.

    .DESCRIPTION
        Create a new MSI based detection rule object to be used for the Add-IntuneWin32App function.

    .PARAMETER MSIProductCode
        Specify the MSI product code for the application.

    .PARAMETER MSIProductVersionOperator
        Specify the MSI product version operator. Supported values are: notConfigured, equal, notEqual, greaterThanOrEqual, greaterThan, lessThanOrEqual or lessThan.

    .PARAMETER MSIProductVersion
        Specify the MSI product version, e.g. 1.0.0.

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
        [parameter(Mandatory = $true, HelpMessage = "Specify the MSI product code for the application.")]
        [ValidateNotNullOrEmpty()]
        [string]$MSIProductCode,

        [parameter(Mandatory = $false, HelpMessage = "Specify the MSI product version operator. Supported values are: notConfigured, equal, notEqual, greaterThanOrEqual, greaterThan, lessThanOrEqual or lessThan.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("notConfigured", "equal", "notEqual", "greaterThanOrEqual", "greaterThan", "lessThanOrEqual", "lessThan")]
        [string]$MSIProductVersionOperator = "notConfigured",

        [parameter(Mandatory = $false, HelpMessage = "Specify the MSI product version, e.g. 1.0.0.")]
        [ValidateNotNullOrEmpty()]
        [string]$MSIProductVersion = [string]::Empty
    )
    Process {
        # Handle initial value for return
        $DetectionRule = $null

        $DetectionRule = [ordered]@{
            "@odata.type" = "#microsoft.graph.win32LobAppProductCodeDetection"
            "productCode" = $MSIProductCode
            "productVersionOperator" = $MSIProductVersionOperator
            "productVersion" = $MSIProductVersion
        }

        # Handle return value with constructed detection rule
        return $DetectionRule
    }
}
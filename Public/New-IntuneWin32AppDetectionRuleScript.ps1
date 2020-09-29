function New-IntuneWin32AppDetectionRuleScript {
    <#
    .SYNOPSIS
        Create a new PowerShell script based detection rule object to be used for the Add-IntuneWin32App function.

    .DESCRIPTION
        Create a new PowerShell script based detection rule object to be used for the Add-IntuneWin32App function.

    .PARAMETER ScriptFile
        Specify the full path to the PowerShell detection script, e.g. 'C:\Scripts\Detection.ps1'.

    .PARAMETER EnforceSignatureCheck
        Specify if PowerShell script signature check should be enforced.

    .PARAMETER RunAs32Bit
        Specify if PowerShell script should be executed as a 32-bit process.

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
        [parameter(Mandatory = $true, HelpMessage = "Specify the full path to the PowerShell detection script, e.g. 'C:\Scripts\Detection.ps1'.")]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptFile,
       
        [parameter(Mandatory = $false, HelpMessage = "Specify if PowerShell script signature check should be enforced.")]
        [ValidateNotNullOrEmpty()]
        [bool]$EnforceSignatureCheck = $false,
       
        [parameter(Mandatory = $false, HelpMessage = "Specify if PowerShell script should be executed as a 32-bit process.")]
        [ValidateNotNullOrEmpty()]
        [bool]$RunAs32Bit = $false
    )
    Process {
        # Handle initial value for return
        $DetectionRule = $null

        # Detect if passed script file exists
        if (Test-Path -Path $ScriptFile) {
            # Convert script file contents to base64 string
            $ScriptContent = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$($ScriptFile)"))

            # Construct detection rule ordered table
            $DetectionRule = [ordered]@{
                "@odata.type" = "#microsoft.graph.win32LobAppPowerShellScriptDetection"
                "enforceSignatureCheck" = $EnforceSignatureCheck
                "runAs32Bit" = $RunAs32Bit
                "scriptContent" = $ScriptContent
            }
        }
        else {
            Write-Warning -Message "Unable to detect the presence of specified script file"
        }

        # Handle return value with constructed detection rule
        return $DetectionRule
    }
}
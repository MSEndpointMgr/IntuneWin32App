function New-IntuneWin32AppDetectionRuleScript {
    <#
    .SYNOPSIS
        Create a new PowerShell script based detection rule object to be used for the Add-IntuneWin32App function.

    .DESCRIPTION
        Create a new PowerShell script based detection rule object to be used for the Add-IntuneWin32App function.

    .PARAMETER ScriptFile
        Specify the full path to the PowerShell detection script, e.g. 'C:\Scripts\Detection.ps1'.

    .PARAMETER ScriptContent
        Specify the PowerShell detection script content as a string, as an alternative to ScriptFile.

    .PARAMETER EnforceSignatureCheck
        Specify if PowerShell script signature check should be enforced.

    .PARAMETER RunAs32Bit
        Specify if PowerShell script should be executed as a 32-bit process.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-09-17
        Updated:     2022-09-02

        Version history:
        1.0.0 - (2020-09-17) Function created
        1.0.1 - (2021-08-31) Fixed an issue when using a non-UTF encoded multi-line script file
        1.0.2 - (2022-09-02) Fixed GitHub reported issue #41 (https://github.com/MSEndpointMgr/IntuneWin32App/issues/41)
        1.0.3 - (2026-11-03) Script files are no longer re-encoded, which corrupted non UTF-8 scripts (#15). Added ScriptContent parameter (#168)
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = "ScriptFile")]
    param(
        [parameter(Mandatory = $true, ParameterSetName = "ScriptFile", HelpMessage = "Specify the full path to the PowerShell detection script, e.g. 'C:\Scripts\Detection.ps1'.")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            # Check if file name contains any invalid characters
            if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
                throw "File name '$(Split-Path -Path $_ -Leaf)' contains invalid characters"
            }
            else {
                # Check if full path exist
                if (Test-Path -Path $_) {
                    # Check if file extension is intunewin
                    if ([System.IO.Path]::GetExtension((Split-Path -Path $_ -Leaf)) -like ".ps1") {
                        return $true
                    }
                    else {
                        throw "Given file name '$(Split-Path -Path $_ -Leaf)' contains an unsupported file extension. Supported extension is '.ps1'"
                    }
                }
                else {
                    throw "File or folder does not exist"
                }
            }
        })]
        [string]$ScriptFile,

        [parameter(Mandatory = $true, ParameterSetName = "ScriptContent", HelpMessage = "Specify the PowerShell detection script content as a string.")]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptContent,

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

        # Convert script file or script content to base64 string
        switch ($PSCmdlet.ParameterSetName) {
            "ScriptFile" {
                $EncodedScriptContent = ConvertTo-IntuneScriptContent -Path $ScriptFile
            }
            "ScriptContent" {
                $EncodedScriptContent = ConvertTo-IntuneScriptContent -Content $ScriptContent
            }
        }

        # Construct detection rule ordered table
        $DetectionRule = [ordered]@{
            "@odata.type" = "#microsoft.graph.win32LobAppPowerShellScriptDetection"
            "enforceSignatureCheck" = $EnforceSignatureCheck
            "runAs32Bit" = $RunAs32Bit
            "scriptContent" = $EncodedScriptContent
        }

        # Handle return value with constructed detection rule
        return $DetectionRule
    }
}
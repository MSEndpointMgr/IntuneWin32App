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
        Updated:     2022-09-02

        Version history:
        1.0.0 - (2020-09-17) Function created
        1.0.1 - (2021-08-31) Fixed an issue when using a non-UTF encoded multi-line script file
        1.0.2 - (2022-09-02) Fixed GitHub reported issue #41 (https://github.com/MSEndpointMgr/IntuneWin32App/issues/41)
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the full path to the PowerShell detection script, e.g. 'C:\Scripts\Detection.ps1'.")]
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
            $ScriptContent = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((Get-Content -Path "$($ScriptFile)" -Raw -Encoding UTF8)))

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
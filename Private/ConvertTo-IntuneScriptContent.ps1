function ConvertTo-IntuneScriptContent {
    <#
    .SYNOPSIS
        Convert a PowerShell script file or script content to a Base64 encoded string for detection and requirement rules.

    .DESCRIPTION
        Convert a PowerShell script file or script content to a Base64 encoded string for detection and requirement rules.
        Script files that are valid UTF-8 (with or without BOM) are uploaded byte for byte. Script files saved with a legacy ANSI code page
        are converted to UTF-8. A UTF-8 BOM is added when the script contains non-ASCII characters, since Windows PowerShell 5.1 on the
        device otherwise reads the script using the system code page and garbles those characters.

    .PARAMETER Path
        Specify the full path to the PowerShell script file.

    .PARAMETER Content
        Specify the PowerShell script content as a string.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2026-11-03
        Updated:     2026-11-03

        Version history:
        1.0.0 - (2026-11-03) Function created (#15, #168)
    #>
    param(
        [parameter(Mandatory = $true, ParameterSetName = "Path", HelpMessage = "Specify the full path to the PowerShell script file.")]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [parameter(Mandatory = $true, ParameterSetName = "Content", HelpMessage = "Specify the PowerShell script content as a string.")]
        [ValidateNotNullOrEmpty()]
        [string]$Content
    )
    Process {
        $UTF8BOM = [byte[]](0xEF, 0xBB, 0xBF)
        $StrictUTF8Encoding = New-Object -TypeName "System.Text.UTF8Encoding" -ArgumentList @($false, $true)

        switch ($PSCmdlet.ParameterSetName) {
            "Path" {
                $ResolvedPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
                $ScriptBytes = [System.IO.File]::ReadAllBytes($ResolvedPath)
                $HasBOM = ($ScriptBytes.Length -ge 3) -and ($ScriptBytes[0] -eq 0xEF) -and ($ScriptBytes[1] -eq 0xBB) -and ($ScriptBytes[2] -eq 0xBF)
                if ($HasBOM) {
                    return [System.Convert]::ToBase64String($ScriptBytes)
                }

                try {
                    $ScriptText = $StrictUTF8Encoding.GetString($ScriptBytes)
                }
                catch [System.Text.DecoderFallbackException] {
                    # Not valid UTF-8, the file was saved using the system code page
                    Write-Verbose -Message "Script file is not UTF-8 encoded, converting from system code page to UTF-8"
                    # Encoding.Default is the system ANSI code page on Windows PowerShell, on PowerShell 7 it is UTF-8 and code page 0 returns the system ANSI code page
                    $AnsiEncoding = [System.Text.Encoding]::Default
                    if ($PSVersionTable.PSEdition -eq "Core") {
                        try {
                            $AnsiEncoding = [System.Text.Encoding]::GetEncoding(0)
                        }
                        catch {
                            Write-Verbose -Message "Unable to determine system ANSI code page, using default encoding"
                        }
                    }
                    $ScriptText = $AnsiEncoding.GetString($ScriptBytes)
                }
            }
            "Content" {
                $ScriptText = $Content
            }
        }

        $ScriptBytes = [System.Text.Encoding]::UTF8.GetBytes($ScriptText)
        if ($ScriptText -match "[^\x00-\x7F]") {
            $ScriptBytes = $UTF8BOM + $ScriptBytes
        }
        return [System.Convert]::ToBase64String($ScriptBytes)
    }
}

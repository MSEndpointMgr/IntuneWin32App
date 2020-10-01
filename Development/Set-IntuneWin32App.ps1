function Set-IntuneWin32App {
    <#
    .SYNOPSIS
        Create a new file based detection rule object to be used for the Add-IntuneWin32App function.

    .DESCRIPTION
        Create a new file based detection rule object to be used for the Add-IntuneWin32App function.

    .PARAMETER Existence
        Define that the detection rule will be existence based, e.g. if a file or folder exists or does not exist.

    .PARAMETER DateModified
        Define that the detection rule will be based on a file or folders date modified value.

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
        [parameter(Mandatory = $true, ParameterSetName = "Existence", HelpMessage = ".")]
        [switch]$AppInformation,
        
        [parameter(Mandatory = $true, ParameterSetName = "Existence", HelpMessage = ".")]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )
    Process {

    }
}
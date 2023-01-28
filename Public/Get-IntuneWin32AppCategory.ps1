function Get-IntuneWin32AppCategory {
    <#
    .SYNOPSIS
        Get all available application categories.

    .DESCRIPTION
        Use this function to retrieve a list of available categories. Then select the desired category or multiple ones by filtering the returned objects by name and pass the ID property 
        as an array for the -Category parameter of the Add-IntuneWin32App function, to include categories when creating a new Win32 application.

    .PARAMETER 
        

    .PARAMETER 
        

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-01-04
        Updated:     2021-09-08

        Version history:
        1.0.0 - (2020-01-04) Function created
        1.0.1 - (2021-09-08) Added return code Failed as valid set for Type parameter input
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the return code value for the Win32 application body.")]
        [ValidateNotNullOrEmpty()]
        [int]$ReturnCode,

        [parameter(Mandatory = $true, HelpMessage = "Specify the type for the return code value for the Win32 application body. Supported values are: success, softReboot, hardReboot, retry or failed.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("success", "softReboot", "hardReboot", "retry", "failed")]
        [string]$Type
    )
    $ReturnCodeTable = @{
        "returnCode" = $ReturnCode
        "type" = $Type
    }

    return $ReturnCodeTable
}
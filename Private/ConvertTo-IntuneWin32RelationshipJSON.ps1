function ConvertTo-IntuneWin32RelationshipJSON {
    <#
    .SYNOPSIS
        Combine supersedence and dependancy into a valid JSON, dealing with the edge cases of 0 and 1 that create 
        "incorrect" JSON using the standard JSON conversion according to the MS API's
        
    .DESCRIPTION
        Combine supersedence and dependancy into a valid JSON, dealing with the edge cases of 0 and 1 that create 
        "incorrect" JSON using the standard JSON conversion according to the MS API's

    .PARAMETER ID
        Specify the ID for an existing Win32 application where supersedence will be configured.

    .PARAMETER Supersedence
        Provide an array of a single or multiple OrderedDictionary objects created with New-IntuneWin32AppSupersedence function.

    .PARAMETER Dependency
        Provide an array of a single or multiple OrderedDictionary objects created with New-IntuneWin32AppDependency function.


    .NOTES
        Author:      Chris Cobb
        Contact:     @crcobb
        Created:     2024-01-29
        Updated:     2023-01-29

        Version history:
        1.0.0 - (2024-01-29) Function created
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Provide an array of a single or multiple OrderedDictionary objects created with New-IntuneWin32AppSupersedence function.")]
        [AllowEmptyCollection()]
        [AllowNull()]
        [System.Collections.Specialized.OrderedDictionary[]]$Supersedence,

        [parameter(Mandatory = $true, HelpMessage = "Provide an array of a single or multiple OrderedDictionary objects created with New-IntuneWin32AppDependency function.")]
        [AllowEmptyCollection()]
        [AllowNull()]
        [System.Collections.Specialized.OrderedDictionary[]]$Dependency
    )
    $Win32AppRelationshipsTable = @()
    if ($Supersedence) { $Win32AppRelationshipsTable += @($Supersedence) } 
    if ($Dependency) { $Win32AppRelationshipsTable += @($Dependency) } 
    
    $JSON = ConvertTo-Json -InputObject @($Win32AppRelationshipsTable)
    if( $null -eq $Win32AppRelationshipsTable ) { $JSON = $JSON.Replace( "null", "[ ]")}
    $JSON = "{ ""relationships"": $($JSON) }" 
    
    return $JSON
}
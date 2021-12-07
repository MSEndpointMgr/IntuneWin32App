function New-IntuneWin32AppDependency {
    <#
    .SYNOPSIS
        Create a new dependency object to be used for the Add-IntuneWin32AppDependency function.

    .DESCRIPTION
        Create a new dependency object to be used for the Add-IntuneWin32AppDependency function.

    .PARAMETER ID
        Specify the ID for an existing Win32 application.

    .PARAMETER DependencyType
        Specify the dependency behavior, use AutoInstall to force install without an assignment requirement and Detect when an assignment is required.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2021-08-31
        Updated:     2021-08-31

        Version history:
        1.0.0 - (2021-08-31) Function created
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the ID for an existing Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID,
        
        [parameter(Mandatory = $true, HelpMessage = "Specify the dependency behavior, use AutoInstall to force install without an assignment requirement and Detect when an assignment is required.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("AutoInstall", "Detect")]
        [string]$DependencyType
    )
    Begin {
        if ($null -eq (Get-MgContext)) {
            Write-Warning -Message "Authentication token was not found, use Connect-MgGraph before using this function"; break
        }

        # Set script variable for error action preference
        $ErrorActionPreference = "Stop"
    }
    Process {
        # Retrieve Win32 app by ID from parameter input
        Write-Verbose -Message "Querying for Win32 app using ID: $($ID)"
        $Win32App = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($ID)" -Method "GET"
        if ($Win32App -ne $null) {
            $Win32AppID = $Win32App.id

            # Handle upper and lower case for dependency type variable
            switch ($DependencyType) {
                "AutoInstall" {
                    $DependencyType = -join@($DependencyType.Substring(0,1).ToLower(), $DependencyType.Substring(1))
                }
                "Detect" {
                    $DependencyType = $DependencyType.ToLower()
                }
            }

            # Construct dependency table
            $Dependency = [ordered]@{
                "@odata.type" = "#microsoft.graph.mobileAppDependency"
                "dependencyType" = $DependencyType
                "targetId" = $Win32AppID
            }

            # Handle return value
            return $Dependency
        }
        else {
            Write-Warning -Message "Query for Win32 app returned an empty result, no apps matching the specified search criteria with ID '$($ID)' was found"
        }
    }
}
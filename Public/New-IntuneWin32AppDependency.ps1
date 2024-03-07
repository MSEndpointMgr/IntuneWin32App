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
        Updated:     2024-01-05

        Version history:
        1.0.0 - (2021-08-31) Function created
        1.0.1 - (2023-09-04) Updated with Test-AccessToken function
        1.0.2 - (2024-01-05) Fixed a type on the Test-AccessToken function implementation
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
        # Ensure required authentication header variable exists
        if ($Global:AuthenticationHeader -eq $null) {
            Write-Warning -Message "Authentication token was not found, use Connect-MSIntuneGraph before using this function"; break
        }
        else {
            if ((Test-AccessToken) -eq $false) {
                Write-Warning -Message "Existing token found but has expired, use Connect-MSIntuneGraph to request a new authentication token"; break
            }
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
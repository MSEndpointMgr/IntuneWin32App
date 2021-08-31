function New-IntuneWin32AppSupersedence {
    <#
    .SYNOPSIS
        Create a new supersedence object to be used for the Add-IntuneWin32AppSupersedence function.

    .DESCRIPTION
        Create a new supersedence object to be used for the Add-IntuneWin32AppSupersedence function.

    .PARAMETER ID
        Specify the ID for an existing Win32 application.

    .PARAMETER SupersedenceType
        Specify the supersedence behavior, use Replace for uninstall and Update for when updating an app.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2021-04-01
        Updated:     2021-08-31

        Version history:
        1.0.0 - (2021-04-01) Function created
        1.0.1 - (2021-08-31) Updated to use new authentication header
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the ID for an existing Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID,
        
        [parameter(Mandatory = $true, HelpMessage = "Specify the supersedence behavior, use Replace for uninstall and Update for when updating an app.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Replace", "Update")]
        [string]$SupersedenceType
    )
    Begin {
        # Ensure required authentication header variable exists
        if ($Global:AuthenticationHeader -eq $null) {
            Write-Warning -Message "Authentication token was not found, use Connect-MSIntuneGraph before using this function"; break
        }
        else {
            $TokenLifeTime = ($Global:AuthenticationHeader.ExpiresOn - (Get-Date).ToUniversalTime()).Minutes
            if ($TokenLifeTime -le 0) {
                Write-Warning -Message "Existing token found but has expired, use Connect-MSIntuneGraph to request a new authentication token"; break
            }
            else {
                Write-Verbose -Message "Current authentication token expires in (minutes): $($TokenLifeTime)"
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

            # Construct supersedence table
            $Supersedence = [ordered]@{
                "@odata.type" = "#microsoft.graph.mobileAppSupersedence"
                "supersedenceType" = $SupersedenceType.ToLower()
                "targetId" = $Win32AppID
            }

            # Handle return value
            return $Supersedence
        }
        else {
            Write-Warning -Message "Query for Win32 app returned an empty result, no apps matching the specified search criteria with ID '$($ID)' was found"
        }
    }
}
Function Get-IntuneWin32AppScopeTag {
    <#
    .SYNOPSIS
        Retrieve all scopetags for a Win32 app.

    .DESCRIPTION
        Retrieve all scopetags for a Win32 app.

    .PARAMETER ID
        Specify the ID for a Win32 application.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2024-08-20
        Updated:     2024-08-20

        Version history:
        1.0.0 - (2024-08-20) Function created
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the ID for an application.")]
        [ValidatePattern("^[a-f0-9]{8}-([a-f0-9]{4}-){3}[a-f0-9]{12}$")]
        [ValidateNotNullOrEmpty()]
        [string]$ID
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
			      # At least one scope tag always exists.
            $ScopeTagsIDs = $Win32App.roleScopeTagIds

            # Output the scope tags directly
            return $ScopeTagsIDs
        }
        else {
            Write-Warning -Message "Query for Win32 app returned an empty result, no apps matching the specified search criteria with ID '$($ID)' was found"
        }
    }
}

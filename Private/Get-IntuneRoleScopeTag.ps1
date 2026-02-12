Function Get-IntuneRoleScopeTag {
    <#
    .SYNOPSIS
        Retrieve all scope tags or a specific one by display name or ID.

    .DESCRIPTION
        Retrieve all scope tags or a specific one by display name or ID.

    .PARAMETER DisplayName
        Specify the display name for a scope tag.

    .PARAMETER ID
        Specify the ID for a scope tag.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2024-08-20
        Updated:     2024-08-20

        Version history:
        1.0.0 - (2024-08-20) Function created
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = "Default")]
    param(
        [parameter(Mandatory = $false, ParameterSetName = "DisplayName", HelpMessage = "Specify the display name for a scope tag.")]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [parameter(Mandatory = $false, ParameterSetName = "ID", HelpMessage = "Specify the ID for a scope tag.")]
        [ValidatePattern("^\d+$")]
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
        switch ($PSCmdlet.ParameterSetName) {
            "DisplayName" {
                # Retrieve role scope tag by DisplayName
                Write-Verbose -Message "Querying for role scope tag using DisplayName: $($DisplayName)"
                $RoleScopeTag = (Invoke-IntuneGraphRequest -APIVersion "Beta" -Route "deviceManagement" -Resource "roleScopeTags?`$filter=displayName eq '$($DisplayName)'" -Method "GET").value 
            }
            "ID" {
                # Retrieve role scope tag by ID
                Write-Verbose -Message "Querying for role scope tag using ID: $($ID)"
                $RoleScopeTag = (Invoke-IntuneGraphRequest -APIVersion "Beta" -Route "deviceManagement" -Resource "roleScopeTags/$($ID)" -Method "GET")
            }
            Default {
                # Retrieve all role scope tags
                Write-Verbose -Message "Querying for all role scope tag"
                $RoleScopeTag = (Invoke-IntuneGraphRequest -APIVersion "Beta" -Route "deviceManagement" -Resource "roleScopeTags" -Method "GET").value
            }
        }
    }
    End {
        if ($RoleScopeTag) {
            return $RoleScopeTag
        }
        else {
            Write-Warning -Message "No role scope tag found matching the specified criteria."
        }
    }
}

Function Remove-IntuneWin32AppScopeTag {
<#
    .SYNOPSIS
        Remove a scope tag from a Win32 app.

    .DESCRIPTION
        Remove a scope tag from a Win32 app.
        If all scope tags are removed, the app automatically add the default ID 0 scope tag.

    .PARAMETER ID
        Specify the ID for a Win32 application.

    .PARAMETER ScopeTagID
        Specify the ID for a scope tag to be removed.

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
        [parameter(Mandatory = $true, ParameterSetName = "ID", HelpMessage = "Specify the ID for an application.")]
        [ValidatePattern("^[a-f0-9]{8}-([a-f0-9]{4}-){3}[a-f0-9]{12}$")]
        [ValidateNotNullOrEmpty()]
        [string]$ID,

        [parameter(Mandatory = $true, ParameterSetName = "ID", HelpMessage = "Specify the ID of the RBAC Scopetag to be removed.")]
        [ValidatePattern("^\d+$")]
        [ValidateNotNullOrEmpty()]
        [string]$ScopeTagID

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
            $roleScopeTagIds = @($Win32App.roleScopeTagIds)
            $UpdateRequired = $false

            # Remove the specified ScopeTag if present
            if ($roleScopeTagIds -contains $ScopeTagID) {
                $roleScopeTagIds = $roleScopeTagIds | Where-Object { $_ -ne $ScopeTagID }
                $UpdateRequired = $true
                Write-Verbose "Removed Scope Tag '$ScopeTagID' from the application."
            }
            else {
                Write-Warning "Scope Tag '$ScopeTagID' is not assigned to the application."
            }

            # Only update if changes were made
            if ($UpdateRequired) {
                $Global:Wn32AppScopeTagTable = [ordered]@{
                    '@odata.type'     = $Win32App.'@odata.type'
                    'roleScopeTagIds' = @($roleScopeTagIds)
                }

                Try {
                    # Attempt to call Graph and update the Win32 app with the new scope tags
                    Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32AppID)" -Method "PATCH" -Body ($Wn32AppScopeTagTable | ConvertTo-Json) -ContentType "application/json" -ErrorAction Stop
                    Write-Verbose -Message "Successfully updated Win32 app scope tags."
                }
                catch [System.Exception] {
                    Write-Warning -Message "An error occurred while updating Win32 app scope tags. Error message: $($_.Exception.Message)"
                }
            }
            else {
                Write-Verbose "No changes were made to the application's scope tags."
            }

        }
        else {
            Write-Warning -Message "Query for Win32 app returned an empty result, no apps matching the specified search criteria with ID '$($ID)' was found"
        }
    }
}

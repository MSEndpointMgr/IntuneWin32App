function Remove-IntuneWin32App {
    <#
    .SYNOPSIS
        Removes a Win32 app.

    .DESCRIPTION
        Removes a Win32 app.

    .PARAMETER DisplayName
        Specify the display name for a Win32 application.

    .PARAMETER ID
        Specify the ID for a Win32 application.

    .NOTES
        Author:      Christof Van Geendertaelen
        Contact:     @cvangeendert
        Created:     2020-11-28
        Updated:     

        Version history:
        1.0.0 - (2020-11-28) Function created
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, ParameterSetName = "DisplayName", HelpMessage = "Specify the display name for a Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [parameter(Mandatory = $true, ParameterSetName = "ID", HelpMessage = "Specify the ID for a Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID      
    )
    Begin {
        # Ensure required auth token exists
        if ($Global:AuthToken -eq $null) {
            Write-Warning -Message "Authentication token was not found, use Connect-MSIntuneGraph before using this function"; break
        }
        else {
            $AuthTokenLifeTime = ($Global:AuthToken.ExpiresOn.datetime - (Get-Date).ToUniversalTime()).Minutes
            if ($AuthTokenLifeTime -le 0) {
                Write-Verbose -Message "Existing token found but has expired, use Connect-MSIntuneGraph to request a new authentication token"; break
            }
            else {
                Write-Verbose -Message "Current authentication token expires in (minutes): $($AuthTokenLifeTime)"
            }
        }

        # Set script variable for error action preference
        $ErrorActionPreference = "Stop"
    }
    Process {
        switch ($PSCmdlet.ParameterSetName) {
            "DisplayName" {
                $MobileApps = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps" -Method "GET"
                if ($MobileApps.value.Count -ge 1) {
                    $Win32MobileApps = $MobileApps.value | Where-Object { $_.'@odata.type' -like "#microsoft.graph.win32LobApp" }
                    if ($Win32MobileApps -ne $null) {
                        $Win32App = $Win32MobileApps | Where-Object { $_.displayName -like $DisplayName }
                        if ($Win32App -ne $null) {
                            Write-Verbose -Message "Detected Win32 app with ID: $($Win32App.id)"
                            $Win32AppID = $Win32App.id
                        }
                        else {
                            Write-Warning -Message "Query for Win32 apps returned empty a result, no apps matching the specified search criteria was found"
                        }
                    }
                    else {
                        Write-Warning -Message "Query for Win32 apps returned empty a result, no apps matching type 'win32LobApp' was found in tenant"
                    }
                }
                else {
                    Write-Warning -Message "Query for mobileApps resources returned empty"
                }
            }
            "ID" {
                $Win32AppID = $ID
            }
        }

        if (-not([string]::IsNullOrEmpty($Win32AppID))) {
            try {
                # Attempt to call Graph and retrieve all assignments for Win32 app
                $Win32AppAssignmentResponse = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32AppID)" -Method "DELETE" -ErrorAction Stop
            }
            catch [System.Exception] {
                Write-Warning -Message "An error occurred while deleting Win32 app with ID: $($Win32AppID). Error message: $($_.Exception.Message)"
            }
        }
        else {
            Write-Warning -Message "Unable to determine the Win32 app identification for deletion"
        }
    }
}
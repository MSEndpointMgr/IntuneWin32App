function Remove-IntuneWin32AppAssignmentAllDevices {
    <#
    .SYNOPSIS
        Remove an 'All Devices' assignment from a Win32 app.

    .DESCRIPTION
        Remove an 'All Devices' assignment from a Win32 app. This will remove the 'All Devices' assignment 
        regardless of the intent (required, available, or uninstall). Since 'All Devices' can only be 
        assigned once across all intents, this function will find and remove whichever intent is currently configured.

    .PARAMETER DisplayName
        Specify the display name for a Win32 application.

    .PARAMETER ID
        Specify the ID for a Win32 application.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2025-12-07
        Updated:     2025-12-07

        Version history:
        1.0.0 - (2025-12-07) Function created
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
                $Win32AppAssignmentResponse = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32AppID)/assignments" -Method "GET" -ErrorAction Stop
                if ($Win32AppAssignmentResponse.value -ne $null) {
                    # Filter for 'All Devices' assignments only
                    $AllDevicesAssignments = $Win32AppAssignmentResponse.value | Where-Object { $_.target.'@odata.type' -eq "#microsoft.graph.allDevicesAssignmentTarget" }
                    
                    if ($AllDevicesAssignments.Count -gt 0) {
                        Write-Verbose -Message "Found $($AllDevicesAssignments.Count) 'All Devices' assignment(s) for removal"
                        
                        # Process each 'All Devices' assignment for removal
                        foreach ($Assignment in $AllDevicesAssignments) {
                            # Determine the intent of the assignment for informative output
                            $AssignmentIntent = $Assignment.intent
                            Write-Verbose -Message "Attempting to remove 'All Devices' assignment with intent '$($AssignmentIntent)' and ID: $($Assignment.id)"
                            
                            try {
                                # Remove current 'All Devices' assignment
                                $Win32AppAssignmentRemoveResponse = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32AppID)/assignments/$($Assignment.id)" -Method "DELETE" -ErrorAction Stop
                                Write-Verbose -Message "Successfully removed 'All Devices' assignment with intent '$($AssignmentIntent)' and ID: $($Assignment.id)"
                            }
                            catch [System.Exception] {
                                Write-Warning -Message "An error occurred while removing 'All Devices' assignment with intent '$($AssignmentIntent)' and ID '$($Assignment.id)'. Error message: $($_.Exception.Message)"
                            }
                        }
                    }
                    else {
                        Write-Verbose -Message "No 'All Devices' assignments found for Win32 app with ID: $($Win32AppID)"
                    }
                }
                else {
                    Write-Verbose -Message "Win32 app does not have any existing assignments"
                }
            }
            catch [System.Exception] {
                Write-Warning -Message "An error occurred while retrieving Win32 app assignments for app with ID: $($Win32AppID). Error message: $($_.Exception.Message)"
            }
        }
        else {
            Write-Warning -Message "Unable to determine the Win32 app identification for assignment removal"
        }
    }
}
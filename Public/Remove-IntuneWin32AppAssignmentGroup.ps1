function Remove-IntuneWin32AppAssignmentGroup {
    <#
    .SYNOPSIS
        Remove a specific Group based on it's ID from the assignments of a Win32 app.

    .DESCRIPTION
        Remove a specific Group based on it's ID from the assignments of a Win32 app.

    .PARAMETER DisplayName
        Specify the display name for a Win32 application.

    .PARAMETER ID
        Specify the ID for a Win32 application.

    .PARAMETER GroupID
        Specify the ID for a group.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2023-09-20
        Updated:     2023-09-20

        Version history:
        1.0.0 - (2023-09-20) Function created
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, ParameterSetName = "DisplayName", HelpMessage = "Specify the display name for a Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [parameter(Mandatory = $true, ParameterSetName = "ID", HelpMessage = "Specify the ID for a Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID,

        [parameter(Mandatory = $true, ParameterSetName = "DisplayName", HelpMessage = "Specify the ID for a group.")]
        [parameter(Mandatory = $true, ParameterSetName = "ID")]
        [ValidateNotNullOrEmpty()]
        [string]$GroupID
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
                $Win32MobileApps = Invoke-MSGraphOperation -Get -APIVersion "Beta" -Resource "deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.win32LobApp')"
                if ($Win32MobileApps -ne $null) {
                    Write-Verbose -Message "Filtering for Win32 apps matching displayName: $($DisplayName)"
                    $Win32MobileApp = $Win32MobileApps | Where-Object { $_.displayName -like $DisplayName }
                    if ($Win32MobileApp -ne $null) {
                        Write-Verbose -Message "Found $($Win32MobileApp.displayName) with ID: $($Win32MobileApp.id)"
                        $Win32AppID = $Win32MobileApp.id
                    }
                    else {
                        Write-Warning -Message "Query for Win32 app returned an empty result, no apps matching the specified search criteria was found"
                    }
                }
                else {
                    Write-Warning -Message "Query for Win32 apps returned an empty result, no apps matching type 'win32LobApp' was found in tenant"
                }
            }
            "ID" {
                $Win32AppID = $ID
            }
        }

        if (-not([string]::IsNullOrEmpty($Win32AppID))) {
            try {
                # Attempt to call Graph and retrieve all assignments for Win32 app
                $Win32AppAssignmentResponse = Invoke-MSGraphOperation -Get -APIVersion "Beta" -Resource "deviceAppManagement/mobileApps/$($Win32AppID)/assignments" -ErrorAction "Stop"
                if ($Win32AppAssignmentResponse -ne $null) {
                    # Process each assignment for removal
                    foreach ($Win32AppAssignment in $Win32AppAssignmentResponse) {
                        if ($Win32AppAssignment.target.groupId -eq $GroupID) {
                            try {
                                # Remove current assignment
                                Write-Verbose -Message "Attempting to remove Win32 app assignment with ID: $($Win32AppAssignment.id)"
                                $Win32AppAssignmentRemoveResponse = Invoke-MSGraphOperation -Delete -APIVersion "Beta" -Resource "deviceAppManagement/mobileApps/$($Win32AppID)/assignments/$($Win32AppAssignment.id)" -ErrorAction "Stop"
                            }
                            catch [System.Exception] {
                                Write-Warning -Message "An error occurred while removing assignment ID '$($Win32AppAssignment.id)' for app with ID: $($Win32AppID). Error message: $($_.Exception.Message)"
                            }
                        }
                    }
                }
                else {
                    Write-Verbose -Message "Unable to locate any instances for removal, Win32 app does not have any existing assignments"
                }
            }
            catch [System.Exception] {
                Write-Warning -Message "An error occurred while retrieving Win32 app assignments for app with ID: $($Win32AppID). Error message: $($_.Exception.Message)"
            }
        }
        else {
            Write-Warning -Message "Unable to determine the Win32 app identification for assignment"
        }
    }
}
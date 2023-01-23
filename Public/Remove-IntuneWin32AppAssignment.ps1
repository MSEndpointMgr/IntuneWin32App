function Remove-IntuneWin32AppAssignment {
    <#
    .SYNOPSIS
        Remove all assignments for a Win32 app.

    .DESCRIPTION
        Remove all assignments for a Win32 app.

    .PARAMETER DisplayName
        Specify the display name for a Win32 application.

    .PARAMETER ID
        Specify the ID for a Win32 application.

    .PARAMETER GroupID
        Specify the Group ID of the assignment you wish to remove. If empty, all assignments will be removed.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-04-29
        Updated:     2023-01-23

        Version history:
        1.0.0 - (2020-04-29) Function created
        1.0.1 - (2021-04-01) Updated token expired message to a warning instead of verbose output
        1.0.2 - (2021-08-31) Updated to use new authentication header
        1.0.3 - (2023-01-23) Updated to allow specific group assignments to be removed
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, ParameterSetName = "DisplayName", HelpMessage = "Specify the display name for a Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [parameter(Mandatory = $true, ParameterSetName = "ID", HelpMessage = "Specify the ID for a Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID,      

        [parameter(Mandatory = $false, HelpMessage = "Specify the Group ID of the assignment you wish to remove. If empty, all assignments will be removed.")]
        [ValidateNotNullOrEmpty()]
        [string]$GroupID      
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
                    $AssignmentCountBefore = ($Win32AppAssignmentResponse.value | Measure-Object).Count
                    Write-Verbose -Message "Count of assignments for Win32 app before attempted removal process: $AssignmentCountBefore"

                    # Process each assignment for removal
                    foreach ($Win32AppAssignment in $Win32AppAssignmentResponse.value) {
                        #Remove if $GroupID matches the group ID of the assignment or if no $GroupID was passed into the function
                        If($Win32AppAssignment.target.groupId -eq $GroupID -or [string]::IsNullOrEmpty($GroupID)){
                            Write-Verbose -Message "Attempting to remove Win32 app assignment with ID: $($Win32AppAssignment.id)"
                        
                            try {
                                # Remove current assignment
                                $Win32AppAssignmentRemoveResponse = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32AppID)/assignments/$($Win32AppAssignment.id)" -Method "DELETE" -ErrorAction Stop
                            }
                            catch [System.Exception] {
                                Write-Warning -Message "An error occurred while retrieving Win32 app assignments for app with ID: $($Win32AppID). Error message: $($_.Exception.Message)"
                            }
                        }
                    }

                    # Calculate amount of remaining assignments after attempted removal process
                    $Win32AppAssignmentResponse = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32AppID)/assignments" -Method "GET" -ErrorAction Stop
                    $AssignmentCountAfter = ($Win32AppAssignmentResponse.value | Measure-Object).Count
                    Write-Verbose -Message "Count of assignments for Win32 app after attempted removal process: $AssignmentCountAfter"
                }
                else {
                    Write-Verbose -Message "Unable to locate any instances for removal, Win32 app does not have any existing assignments"
                }

                If($AssignmentCountBefore -eq $AssignmentCountAfter){
                    Write-Warning -Message "The count of assignments before and after running are the same. No assignments have been removed."
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
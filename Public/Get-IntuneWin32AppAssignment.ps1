function Get-IntuneWin32AppAssignment {
    <#
    .SYNOPSIS
        Retrieve all assignments for a Win32 app.

    .DESCRIPTION
        Retrieve all assignments for a Win32 app.

    .PARAMETER DisplayName
        Specify the display name for a Win32 application.

    .PARAMETER ID
        Specify the ID for a Win32 application.

    .PARAMETER GroupName
        Specify a group name to scope assignments targeted for that group.

    .PARAMETER Intent
        Specify the intent to further scope the group name assignment.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-04-29
        Updated:     2024-01-05

        Version history:
        1.0.0 - (2020-04-29) Function created
        1.0.1 - (2020-05-26) Added new parameter GroupName to be able to retrieve assignments associated with a given group
        1.0.2 - (2020-09-23) Added Intent parameter to be able to further scope the desired assignments being retrieved
        1.0.3 - (2020-12-18) Improved output to a list instead, also added a new output property 'GroupMode' to show if the assignment is either Include or Exclude
        1.0.4 - (2021-04-01) Updated token expired message to a warning instead of verbose output
        1.0.5 - (2021-08-31) Updated to use new authentication header
        1.0.6 - (2023-09-04) Updated with Test-AccessToken function. Added new properties in the output of assignments, such as FilterID, FilterType, DeliveryOptimizationPriority, Notifications, RestartSettings and InstallTimeSettings.
        1.0.7 - (2024-01-05) Improved the property output from function to include the same properties independent of the parameter set name used
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, ParameterSetName = "DisplayName", HelpMessage = "Specify the display name for a Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [parameter(Mandatory = $true, ParameterSetName = "ID", HelpMessage = "Specify the ID for a Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID,

        [parameter(Mandatory = $true, ParameterSetName = "Group", HelpMessage = "Specify a group name to scope assignments targeted for that group.")]
        [ValidateNotNullOrEmpty()]
        [string]$GroupName,

        [parameter(Mandatory = $false, ParameterSetName = "Group", HelpMessage = "Specify the intent to further scope the group name assignment.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("required", "available", "uninstall")]
        [string]$Intent
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
        # Construct list of Win32 apps to query for assignments
        $Win32AppList = New-Object -TypeName "System.Collections.Generic.List[Object]"

        switch ($PSCmdlet.ParameterSetName) {
            "DisplayName" {
                $Win32MobileApps = Invoke-MSGraphOperation -Get -APIVersion "Beta" -Resource "deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.win32LobApp')"
                if ($Win32MobileApps -ne $null) {
                    Write-Verbose -Message "Filtering for Win32 apps matching displayName: $($DisplayName)"
                    $Win32MobileApps = $Win32MobileApps | Where-Object { $_.displayName -like "*$($DisplayName)*" }
                    if ($Win32MobileApps -ne $null) {
                        foreach ($Win32MobileApp in $Win32MobileApps) {
                            $Win32App = Invoke-MSGraphOperation -Get -APIVersion "Beta" -Resource "deviceAppManagement/mobileApps/$($Win32MobileApp.id)"
                            $Win32AppList.Add($Win32App)
                        }
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
                try {
                    $Win32MobileApp = Invoke-MSGraphOperation -Get -APIVersion "Beta" -Resource "deviceAppManagement/mobileApps/$($ID)" -ErrorAction "Stop"
                    if ($Win32MobileApp -ne $null) {
                        $Win32AppList.Add($Win32MobileApp)
                    }
                    else {
                        Write-Warning -Message "Query for Win32 apps returned an empty result, no apps matching ID '$($ID)' was found in tenant"
                    }
                }
                catch [System.Exception] {
                    Write-Warning -Message "An error occurred while retrieving Win32 app with ID: $($ID). Error message: $($_.Exception.Message)"
                }
            }
            "Group" {
                $Win32MobileApps = Invoke-MSGraphOperation -Get -APIVersion "Beta" -Resource "deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.win32LobApp')"
                if ($Win32MobileApps -ne $null) {
                    foreach ($Win32MobileApp in $Win32MobileApps) {
                        $Win32AppList.Add($Win32MobileApp) | Out-Null
                    }
                }
                else {
                    Write-Warning -Message "Query for Win32 apps returned empty a result, no apps matching type 'win32LobApp' was found in tenant"
                }
            }
        }

        # Construct list for output of matches
        $Win32AppAssignmentList = New-Object -TypeName "System.Collections.Generic.List[Object]"

        # Continue if Win32 app list is not empty
        if ($Win32AppList.Count -ge 1) {
            foreach ($Win32MobileApp in $Win32AppList) {
                try {
                    # Attempt to call Graph and retrieve all assignments for each Win32 app
                    $Win32AppAssignmentResponse = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32MobileApp.id)/assignments" -Method "GET" -ErrorAction Stop
                    if ($Win32AppAssignmentResponse.value -ne $null) {
                        if ($PSCmdlet.ParameterSetName -eq "Group") {
                            if ($PSBoundParameters["Intent"]) {
                                $Win32AppAssignmentMatches = $Win32AppAssignmentResponse.value | Where-Object { ($PSItem.target.'@odata.type' -like "*groupAssignmentTarget") -and ($PSItem.intent -like $Intent) }
                            }
                            else {
                                $Win32AppAssignmentMatches = $Win32AppAssignmentResponse.value | Where-Object { $PSItem.target.'@odata.type' -like "*groupAssignmentTarget" }
                            }
    
                            foreach ($Win32AppAssignment in $Win32AppAssignmentMatches) {
                                try {
                                    # Retrieve group name from given group id
                                    $AzureADGroupResponse = Invoke-AzureADGraphRequest -Resource "groups/$($Win32AppAssignment.target.groupId)" -Method "GET"
                                    if ($AzureADGroupResponse.displayName -like "*$($GroupName)*") {
                                        Write-Verbose -Message "Win32 app assignment '$($Win32AppAssignment.id)' for app '$($Win32MobileApp.displayName)' matched group name: $($GroupName)"
    
                                        # Determine if assignment is either Include or Exclude for GroupMode property output
                                        switch ($Win32AppAssignment.target.'@odata.type') {
                                            "#microsoft.graph.groupAssignmentTarget" {
                                                $GroupMode = "Include"
                                            }
                                            "#microsoft.graph.exclusionGroupAssignmentTarget" {
                                                $GroupMode = "Exclude"
                                            }
                                        }
    
                                        # Create a custom object for return value
                                        $PSObject = [PSCustomObject]@{
                                            Type = $Win32AppAssignment.target.'@odata.type'
                                            AppName = $Win32MobileApp.displayName
                                            FilterID = $Win32AppAssignment.target.deviceAndAppManagementAssignmentFilterId
                                            FilterType = $Win32AppAssignment.target.deviceAndAppManagementAssignmentFilterType
                                            GroupID = $Win32AppAssignment.target.groupId
                                            GroupName = $AzureADGroupResponse.displayName
                                            Intent = $Win32AppAssignment.intent
                                            GroupMode = $GroupMode
                                            DeliveryOptimizationPriority = $Win32AppAssignment.settings.deliveryOptimizationPriority
                                            Notifications = $Win32AppAssignment.settings.notifications
                                            RestartSettings = $Win32AppAssignment.settings.restartSettings
                                            InstallTimeSettings = $Win32AppAssignment.settings.installTimeSettings
                                        }
                                        $Win32AppAssignmentList.Add($PSObject) | Out-Null
                                    }
                                }
                                catch [System.Exception] {
                                    Write-Warning -Message "An error occurred while resolving groupId for assignment with ID: $($Win32AppAssignment.id). Error message: $($_.Exception.Message)"
                                }
                            }
                        }
                        else {
                            foreach ($Win32AppAssignment in $Win32AppAssignmentResponse.value) {
                                # Determine if assignment is either Include or Exclude for GroupMode property output
                                switch ($Win32AppAssignment.target.'@odata.type') {
                                    "#microsoft.graph.groupAssignmentTarget" {
                                        $GroupMode = "Include"
                                    }
                                    "#microsoft.graph.exclusionGroupAssignmentTarget" {
                                        $GroupMode = "Exclude"
                                    }
                                }

                                # If data type is of type 'groupAssignmentTarget' then retrieve group name from given group id
                                if ($Win32AppAssignment.target.'@odata.type' -like '*groupAssignmentTarget') {
                                    $AzureADGroupResponse = Invoke-AzureADGraphRequest -Resource "groups/$($Win32AppAssignment.target.groupId)" -Method "GET"
                                }
                                else {
                                    $AzureADGroupResponse = $null
                                }

                                # Create a custom object for return value
                                $PSObject = [PSCustomObject]@{
                                    Type = $Win32AppAssignment.target.'@odata.type'
                                    AppName = $Win32MobileApp.displayName
                                    FilterID = $Win32AppAssignment.target.deviceAndAppManagementAssignmentFilterId
                                    FilterType = $Win32AppAssignment.target.deviceAndAppManagementAssignmentFilterType
                                    GroupID = $Win32AppAssignment.target.groupId
                                    GroupName = if ($AzureADGroupResponse -ne $null) { $AzureADGroupResponse.displayName } else { $null }
                                    Intent = $Win32AppAssignment.intent
                                    GroupMode = $GroupMode
                                    DeliveryOptimizationPriority = $Win32AppAssignment.settings.deliveryOptimizationPriority
                                    Notifications = $Win32AppAssignment.settings.notifications
                                    RestartSettings = $Win32AppAssignment.settings.restartSettings
                                    InstallTimeSettings = $Win32AppAssignment.settings.installTimeSettings
                                }
                                $Win32AppAssignmentList.Add($PSObject) | Out-Null
                            }
                        }
                    }
                    else {
                        Write-Warning -Message "Empty response for assignments for Win32 app: $($Win32MobileApp.displayName)"
                    }
                }
                catch [System.Exception] {
                    Write-Warning -Message "An error occurred while retrieving Win32 app assignments for app with ID: $($Win32MobileApp.id). Error message: $($_.Exception.Message)"
                }
            }
    
            # Handle return value
            return $Win32AppAssignmentList
        }
    }
}
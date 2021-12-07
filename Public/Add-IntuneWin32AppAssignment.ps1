function Add-IntuneWin32AppAssignment {
    <#
    .SYNOPSIS
        Add an assignment to a Win32 app.

    .DESCRIPTION
        Add an assignment to a Win32 app.

    .PARAMETER DisplayName
        Specify the display name for a Win32 application.

    .PARAMETER ID
        Specify the ID for a Win32 application.

    .PARAMETER Target
        Specify the target of the assignment, either AllUsers, AllDevices or Group.

    .PARAMETER Intent
        Specify the intent of the assignment, either required or available.

    .PARAMETER GroupMode
        Specify whether the assignment should be set to include or to exclude.

    .PARAMETER GroupID
        Specify the ID for an Azure AD group.

    .PARAMETER Notification
        Specify the notification setting for the assignment of the Win32 app.

    .PARAMETER AvailableTime
        Specify a date time object for the availability of the assignment.

    .PARAMETER DeadlineTime
        Specify a date time object for the deadline of the assignment.

    .PARAMETER UseLocalTime
        Specify to use either UTC of device local time for the assignment, set to 'True' for device local time and 'False' for UTC.

    .PARAMETER DeliveryOptimizationPriority
        Specify to download content in the background using default value of 'notConfigured', or set to download in foreground using 'foreground'.

    .PARAMETER EnableRestartGracePeriod
        Specify whether Restart Grace Period functionality for this assignment should be configured, additional parameter input using at least RestartGracePeriod and RestartCountDownDisplay is required.

    .PARAMETER RestartGracePeriod
        Specify the device restart grace period in minutes.

    .PARAMETER RestartCountDownDisplay
        Specify a count in minutes when the restart count down display box is shown.

    .PARAMETER RestartNotificationSnooze
        Specify a count in minutes for snoozing the restart notification, if not specified the snooze functionality is now allowed.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-01-04
        Updated:     2021-08-31

        Version history:
        1.0.0 - (2020-01-04) Function created
        1.0.1 - (2020-04-29) Added support for AllDevices target assignment type
        1.0.2 - (2020-06-08) Added support for Available and Deadline settings, device local time and Delivery Optimization settings of the assignment
        1.0.3 - (2020-08-05) Added support for additional restart settings
        1.0.4 - (2021-04-01) Updated token expired message to a warning instead of verbose output
        1.0.5 - (2021-08-31) Updated to use new authentication header
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, ParameterSetName = "DisplayName", HelpMessage = "Specify the display name for a Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [parameter(Mandatory = $true, ParameterSetName = "ID", HelpMessage = "Specify the ID for a Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID,

        [parameter(Mandatory = $true, ParameterSetName = "DisplayName", HelpMessage = "Specify the target of the assignment, either AllUsers, AllDevices or Group.")]
        [parameter(Mandatory = $true, ParameterSetName = "ID")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("AllUsers", "AllDevices", "Group")]
        [string]$Target,

        [parameter(Mandatory = $false, ParameterSetName = "DisplayName", HelpMessage = "Specify the intent of the assignment, either required or available.")]
        [parameter(Mandatory = $false, ParameterSetName = "ID")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("required", "available", "uninstall")]
        [string]$Intent = "available",

        [parameter(Mandatory = $false, ParameterSetName = "DisplayName", HelpMessage = "Specify whether the assignment should be set to include or to exclude.")]
        [parameter(Mandatory = $false, ParameterSetName = "ID")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Include", "Exclude")]
        [string]$GroupMode = "Include",

        [parameter(Mandatory = $false, ParameterSetName = "DisplayName", HelpMessage = "Specify the ID for an Azure AD group.")]
        [parameter(Mandatory = $false, ParameterSetName = "ID")]
        [ValidateNotNullOrEmpty()]
        [string]$GroupID,

        [parameter(Mandatory = $false, ParameterSetName = "DisplayName", HelpMessage = "Specify the notification setting for the assignment of the Win32 app.")]
        [parameter(Mandatory = $false, ParameterSetName = "ID")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("showAll", "showReboot", "hideAll")]
        [string]$Notification = "showAll",

        [parameter(Mandatory = $false, ParameterSetName = "DisplayName", HelpMessage = "Specify a date time object for the availability of the assignment.")]
        [parameter(Mandatory = $false, ParameterSetName = "ID")]
        [ValidateNotNullOrEmpty()]
        [datetime]$AvailableTime,

        [parameter(Mandatory = $false, ParameterSetName = "DisplayName", HelpMessage = "Specify a date time object for the deadline of the assignment.")]
        [parameter(Mandatory = $false, ParameterSetName = "ID")]
        [ValidateNotNullOrEmpty()]
        [datetime]$DeadlineTime,

        [parameter(Mandatory = $false, ParameterSetName = "DisplayName", HelpMessage = "Specify to use either UTC of device local time for the assignment, set to 'True' for device local time and 'False' for UTC.")]
        [parameter(Mandatory = $false, ParameterSetName = "ID")]
        [ValidateNotNullOrEmpty()]
        [bool]$UseLocalTime = $false,

        [parameter(Mandatory = $false, ParameterSetName = "DisplayName", HelpMessage = "Specify to download content in the background using default value of 'notConfigured', or set to download in foreground using 'foreground'.")]
        [parameter(Mandatory = $false, ParameterSetName = "ID")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("notConfigured", "foreground")]
        [string]$DeliveryOptimizationPriority = "notConfigured",

        [parameter(Mandatory = $false, ParameterSetName = "DisplayName", HelpMessage = "Specify whether Restart Grace Period functionality for this assignment should be configured, additional parameter input using at least RestartGracePeriod and RestartCountDownDisplay is required.")]
        [parameter(Mandatory = $false, ParameterSetName = "ID")]
        [ValidateNotNullOrEmpty()]
        [bool]$EnableRestartGracePeriod = $false,

        [parameter(Mandatory = $false, ParameterSetName = "DisplayName", HelpMessage = "Specify the device restart grace period in minutes.")]
        [parameter(Mandatory = $false, ParameterSetName = "ID")]
        [ValidateNotNullOrEmpty()]
        [ValidateRange("1", "20160")]
        [int]$RestartGracePeriod = 1440,

        [parameter(Mandatory = $false, ParameterSetName = "DisplayName", HelpMessage = "Specify a count in minutes when the restart count down display box is shown.")]
        [parameter(Mandatory = $false, ParameterSetName = "ID")]
        [ValidateNotNullOrEmpty()]
        [ValidateRange("1", "240")]
        [int]$RestartCountDownDisplay = 15,
        
        [parameter(Mandatory = $false, ParameterSetName = "DisplayName", HelpMessage = "Specify a count in minutes for snoozing the restart notification, if not specified the snooze functionality is now allowed.")]
        [parameter(Mandatory = $false, ParameterSetName = "ID")]
        [ValidateNotNullOrEmpty()]
        [ValidateRange("1", "712")]
        [int]$RestartNotificationSnooze = 240
    )
    Begin {
        Write-Warning -Message "This function is no longer under active development and will be removed in an upcoming release"
        Write-Warning -Message "Use any of the following functions instead:"
        Write-Warning -Message "- Add-IntuneWin32AppAssignmentAllDevices"
        Write-Warning -Message "- Add-IntuneWin32AppAssignmentAllUsers"
        Write-Warning -Message "- Add-IntuneWin32AppAssignmentGroup"

        # Ensure required authentication header variable exists
        if ($null -eq (Get-MgContext)) {
            Write-Warning -Message "Authentication token was not found, use Connect-MgGraph before using this function"; break
        }

        # Set script variable for error action preference
        $ErrorActionPreference = "Stop"

        # Validate group identifier is passed as input if target is set to Group
        if ($Target -like "Group") {
            if (-not($PSBoundParameters["GroupID"])) {
                Write-Warning -Message "Validation failed for parameter input, target set to Group but GroupID parameter was not specified"; break
            }
        }

        # Validate correct intent is used when target is AllDevices or AllUsers
        if ($Target -in @("AllDevices", "AllUsers")) {
            Write-Verbose -Message "Target was specified as '$($Target)', setting intent to: Required"
            $Intent = "required"
        }

        # Validate that Available parameter input datetime object is in the past if the Deadline parameter is not passed on the command line
        if ($PSBoundParameters["AvailableTime"]) {
            if (-not($PSBoundParameters["DeadlineTime"])) {
                if ($AvailableTime -gt (Get-Date).AddDays(-1)) {
                    Write-Warning -Message "Validation failed for parameter input, available date time needs to be before the current used 'as soon as possible' deadline date and time, with a offset of 1 day"; break
                }
            }
        }

        # Validate that Deadline parameter input datetime object is in the future if the Available parameter is not passed on the command line
        if ($PSBoundParameters["DeadlineTime"]) {
            if (-not($PSBoundParameters["AvailableTime"])) {
                if ($DeadlineTime -lt (Get-Date)) {
                    Write-Warning -Message "Validation failed for parameter input, deadline date time needs to be after the current used 'as soon as possible' available date and time"; break
                }
            }
        }

        # Output warning message that additional required parameters for restart grace period was not specified and default values will be used
        if ($PSBoundParameters["EnableRestartGracePeriod"]) {
            if (-not($PSBoundParameters["RestartGracePeriod"])) {
                Write-Warning -Message "EnableRestartGracePeriod parameter was specified but required parameter RestartGracePeriod was not, using default value of: $($RestartGracePeriod)"
            }

            if (-not($PSBoundParameters["RestartCountDownDisplay"])) {
                Write-Warning -Message "EnableRestartGracePeriod parameter was specified but required parameter RestartCountDownDisplay was not, using default value of: $($RestartCountDownDisplay)"
            }
        }

        # Disable RestartNotificationSnooze functionality and set object to null if not passed on command line
        if (-not($PSBoundParameters["RestartNotificationSnooze"])) {
            [System.Object]$RestartNotificationSnooze = $null
            Write-Verbose -Message "RestartNotificationSnooze parameter was not specified, which means 'Allow user to snooze the restart notification' functionality will be disabled for this assignment"
        }
    }
    Process {
        # Static variables
        $ProceedExecution = $true

        switch ($PSCmdlet.ParameterSetName) {
            "DisplayName" {
                Write-Verbose -Message "Attempting to retrieve all win32LobApp mobileApps type resources to determine ID of Win32 app with display name: $($DisplayName)"
                $Win32MobileApps = (Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps?`$filter=isof('microsoft.graph.win32LobApp')" -Method "GET").value
                if ($Win32MobileApps.Count -ge 1) {
                    $Win32MobileApp = $Win32MobileApps | Where-Object { $_.displayName -like "$($DisplayName)" }
                    if ($Win32MobileApp -ne $null) {
                        if (($Win32MobileApp | Measure-Object).Count -eq 1) {
                            Write-Verbose -Message "Querying for Win32 app using ID: $($Win32MobileApp.id)"
                            $Win32App = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32MobileApp.id)" -Method "GET"
                            $Win32AppID = $Win32App.id
                        }
                        else {
                            Write-Warning -Message "Multiple Win32 apps was returned after filtering for display name, please refine the input parameters"; break
                        }
                    }
                    else {
                        Write-Warning -Message "Query for Win32 app returned an empty result, no apps matching the specified search criteria with display name '$($DisplayName)' was found"
                    }
                }
            }
            "ID" {
                Write-Verbose -Message "Querying for Win32 app using ID: $($ID)"
                $Win32App = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($ID)" -Method "GET"
                if ($Win32App -ne $null) {
                    $Win32AppID = $Win32App.id   
                }
                else {
                    Write-Warning -Message "Query for Win32 app returned an empty result, no apps matching the specified search criteria with ID '$($ID)' was found"
                }
            }
        }

        if (-not([string]::IsNullOrEmpty($Win32AppID))) {
            # Determine target property body based on parameter input
            switch ($Target) {
                "AllUsers" {
                    $TargetAssignment = @{
                        "@odata.type" = "#microsoft.graph.allLicensedUsersAssignmentTarget"
                        "deviceAndAppManagementAssignmentFilterId" = $null
                        "deviceAndAppManagementAssignmentFilterType" = "none"
                    }                    
                }
                "AllDevices" {
                    $TargetAssignment = @{
                        "@odata.type" = "#microsoft.graph.allDevicesAssignmentTarget"
                        "deviceAndAppManagementAssignmentFilterId" = $null
                        "deviceAndAppManagementAssignmentFilterType" = "none"
                    }                    
                }
                "Group" {
                    $TargetAssignment = @{
                        "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
                        "deviceAndAppManagementAssignmentFilterId" = $null
                        "deviceAndAppManagementAssignmentFilterType" = "none"
                        "groupId" = $GroupID
                    }
                }
            }

            # Construct table for Win32 app assignment body
            $Win32AppAssignmentBody = [ordered]@{
                "@odata.type" = "#microsoft.graph.mobileAppAssignment"
                "intent" = $Intent
                "source" = "direct"
                "target" = $TargetAssignment
                "settings" = @{
                    "@odata.type" = "#microsoft.graph.win32LobAppAssignmentSettings"
                    "notifications" = $Notification
                    "restartSettings" = $null
                    "deliveryOptimizationPriority" = $DeliveryOptimizationPriority
                    "installTimeSettings" = $null
                }
            }

            # Amend installTimeSettings property if Available parameter is specified
            if (($PSBoundParameters["Available"]) -and (-not($PSBoundParameters["Deadline"]))) {
                $Win32AppAssignmentBody.settings.installTimeSettings = @{
                    "useLocalTime" = $UseLocalTime
                    "startDateTime" = (ConvertTo-JSONDate -InputObject $Available)
                    "deadlineDateTime" = $null
                }
            }

            # Amend installTimeSettings property if Deadline parameter is specified
            if (($PSBoundParameters["Deadline"]) -and (-not($PSBoundParameters["Available"]))) {
                $Win32AppAssignmentBody.settings.installTimeSettings = @{
                    "useLocalTime" = $UseLocalTime
                    "startDateTime" = $null
                    "deadlineDateTime" = (ConvertTo-JSONDate -InputObject $Deadline)
                }
            }

            # Amend installTimeSettings property if Available and Deadline parameter is specified
            if (($PSBoundParameters["Available"]) -and ($PSBoundParameters["Deadline"])) {
                $Win32AppAssignmentBody.settings.installTimeSettings = @{
                    "useLocalTime" = $UseLocalTime
                    "startDateTime" = (ConvertTo-JSONDate -InputObject $Available)
                    "deadlineDateTime" = (ConvertTo-JSONDate -InputObject $Deadline)
                }
            }

            # Amend restartSettings if app restart behavior is set to baseOnReturnCode and EnableRestartGracePeriod is set to True
            if ($EnableRestartGracePeriod -eq $true) {
                if ($Win32App.installExperience.deviceRestartBehavior -like "basedOnReturnCode") {
                    Write-Verbose -Message "Detected that Win32 app was configured for restart settings, adding parameter inputs to request"

                    $Win32AppAssignmentBody.settings.restartSettings = @{
                        "gracePeriodInMinutes" = $RestartGracePeriod
                        "countdownDisplayBeforeRestartInMinutes" = $RestartCountDownDisplay
                        "restartNotificationSnoozeDurationInMinutes" = $RestartNotificationSnooze
                    }
                }
                else {
                    Write-Warning -Message "Win32 app was not configured for restart settings, ensure restart behavior is configured with 'Based on return code'"
                }
            }

            # Validate that targeted Win32 app doesn't already have an assignment for the target type of either AllDevices, AllUsers or an existing security group before attempting to post the assignment request
            try {
                Write-Verbose -Message "Retrieving any existing Win32 app assignments to validate existing assignments for duplicate resources"
                $Win32AppAssignments = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32AppID)/assignments" -Method "GET" -ErrorAction Stop
                $Win32AppAssignmentsCount = ($Win32AppAssignments.value | Measure-Object).Count
                if ($Win32AppAssignmentsCount -ge 1) {
                    Write-Verbose -Message "Detected count of '$($Win32AppAssignmentsCount)' existing assignments, processing each item for validation"

                    # Define target types for AllDevices and AllUsers
                    switch ($Target) {
                        "AllDevices" {
                            $TargetType = "allDevicesAssignmentTarget"
                        }
                        "AllUsers" {
                            $TargetType = "allLicensedUsersAssignmentTarget"
                        }
                    }
                    
                    # Validate existing target types
                    switch ($Target) {
                        "Group" {
                            foreach ($Win32AppAssignment in $Win32AppAssignments.value) {
                                if ($Win32AppAssignment.target.'@odata.type' -match "groupAssignmentTarget") {
                                    if ($Win32AppAssignment.target.groupId -like $GroupID) {
                                        Write-Warning -Message "Win32 app assignment with id '$($Win32AppAssignment.id)' of target type '$($Target)' and GroupID '$($Win32AppAssignment.target.groupId)' already exists, duplicate assignments of this type is not permitted"
                                        $ProceedExecution = $false
                                    }
                                }
                            }
                        }
                        default {
                            foreach ($Win32AppAssignment in $Win32AppAssignments.value) {
                                if ($Win32AppAssignment.target.'@odata.type' -match $TargetType) {
                                    Write-Warning -Message "Win32 app assignment with id '$($Win32AppAssignment.id)' of target type '$($Target)' already exists, duplicate assignments of this type is not permitted"
                                    $ProceedExecution = $false
                                }
                            }
                        }
                    }

                    if ($ProceedExecution -eq $true) {
                        try {
                            # Attempt to call Graph and create new assignment for Win32 app
                            $Win32AppAssignmentResponse = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32AppID)/assignments" -Method "POST" -Body ($Win32AppAssignmentBody | ConvertTo-Json) -ContentType "application/json" -ErrorAction Stop
                            if ($Win32AppAssignmentResponse.id) {
                                Write-Verbose -Message "Successfully created Win32 app assignment with ID: $($Win32AppAssignmentResponse.id)"
                                Write-Output -InputObject $Win32AppAssignmentResponse
                            }
                        }
                        catch [System.Exception] {
                            Write-Warning -Message "An error occurred while creating a Win32 app assignment: $($TargetFilePath). Error message: $($_.Exception.Message)"
                        }
                    }
                }
                else {
                    Write-Verbose -Message "Detected count of '$($Win32AppAssignmentsCount)', skipping assignment validation for existence of AllDevices or AllUsers"
                }
            }
            catch [System.Exception] {
                Write-Warning -Message "Failed to validate if Win32 app already has an existing assignment target type of '$($Target)'"
            }
        }
        else {
            Write-Warning -Message "Unable to determine the Win32 app identification for assignment"
        }
    }
}
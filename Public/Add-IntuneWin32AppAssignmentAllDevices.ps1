function Add-IntuneWin32AppAssignmentAllDevices {
    <#
    .SYNOPSIS
        Add an 'All Devices' assignment to a Win32 app.

    .DESCRIPTION
        Add an 'All Devices' assignment to a Win32 app.

    .PARAMETER ID
        Specify the ID for a Win32 application.

    .PARAMETER Intent
        Specify the intent of the assignment, either required, available or uninstall.

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

    .PARAMETER FilterName
        Specify the name of an existing Filter.

    .PARAMETER FilterMode
        Specify the filter mode of the specified Filter, e.g. Include or Exclude.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-09-20
        Updated:     2023-09-04

        Version history:
        1.0.0 - (2020-09-20) Function created
        1.0.1 - (2021-04-01) Updated token expired message to a warning instead of verbose output
        1.0.2 - (2021-08-31) Updated to use new authentication header
        1.0.3 - (2023-09-04) Updated with Test-AccessToken function
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the ID for a Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID,

        [parameter(Mandatory = $true, HelpMessage = "Specify the intent of the assignment, either required, available or uninstall.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("required", "available", "uninstall")]
        [string]$Intent,

        [parameter(Mandatory = $false, HelpMessage = "Specify the notification setting for the assignment of the Win32 app.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("showAll", "showReboot", "hideAll")]
        [string]$Notification = "showAll",

        [parameter(Mandatory = $false, HelpMessage = "Specify a date time object for the availability of the assignment.")]
        [ValidateNotNullOrEmpty()]
        [datetime]$AvailableTime,

        [parameter(Mandatory = $false, HelpMessage = "Specify a date time object for the deadline of the assignment.")]
        [ValidateNotNullOrEmpty()]
        [datetime]$DeadlineTime,

        [parameter(Mandatory = $false, HelpMessage = "Specify to use either UTC of device local time for the assignment, set to 'True' for device local time and 'False' for UTC.")]
        [ValidateNotNullOrEmpty()]
        [bool]$UseLocalTime = $false,

        [parameter(Mandatory = $false, HelpMessage = "Specify to download content in the background using default value of 'notConfigured', or set to download in foreground using 'foreground'.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("notConfigured", "foreground")]
        [string]$DeliveryOptimizationPriority = "notConfigured",

        [parameter(Mandatory = $false, HelpMessage = "Specify whether Restart Grace Period functionality for this assignment should be configured, additional parameter input using at least RestartGracePeriod and RestartCountDownDisplay is required.")]
        [ValidateNotNullOrEmpty()]
        [bool]$EnableRestartGracePeriod = $false,

        [parameter(Mandatory = $false, HelpMessage = "Specify the device restart grace period in minutes.")]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 20160)]
        [int]$RestartGracePeriod = 1440,

        [parameter(Mandatory = $false, HelpMessage = "Specify a count in minutes when the restart count down display box is shown.")]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 240)]
        [int]$RestartCountDownDisplay = 15,
        
        [parameter(Mandatory = $false, HelpMessage = "Specify a count in minutes for snoozing the restart notification, if not specified the snooze functionality is now allowed.")]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 712)]
        [int]$RestartNotificationSnooze = 240,

        [parameter(Mandatory = $false, HelpMessage = "Specify the name of an existing Filter.")]
        [ValidateNotNullOrEmpty()]
        [string]$FilterName,

        [parameter(Mandatory = $false, HelpMessage = "Specify the filter mode of the specified Filter, e.g. Include or Exclude.")]
        [ValidateSet("Include", "Exclude")]
        [string]$FilterMode
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
        # Get Filter object if parameter is passed on command line
        if ($PSBoundParameters["FilterName"]) {
            # Ensure Filter mode is lowercase
            $FilterMode = $FilterMode.ToLower()

            # Ensure a Filter exist by given name from parameter input
            Write-Verbose -Message "Querying for specified Filter: $($FilterName)"
            $AssignmentFilters = Invoke-MSGraphOperation -Get -APIVersion "Beta" -Resource "deviceManagement/assignmentFilters" -Verbose
            if ($AssignmentFilters -ne $null) {
                $AssignmentFilter = $AssignmentFilters | Where-Object { $PSItem.displayName -eq $FilterName }
                if ($AssignmentFilter -ne $null) {
                    Write-Verbose -Message "Found Filter with display name '$($AssignmentFilter.displayName)' and id: $($AssignmentFilter.id)"
                }
                else {
                    Write-Warning -Message "Could not find Filter with display name: '$($FilterName)'"
                }
            }
        }

        # Retrieve Win32 app by ID from parameter input
        Write-Verbose -Message "Querying for Win32 app using ID: $($ID)"
        $Win32App = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($ID)" -Method "GET"
        if ($Win32App -ne $null) {
            $Win32AppID = $Win32App.id

            # Construct target assignment body
            $TargetAssignment = @{
                "@odata.type" = "#microsoft.graph.allDevicesAssignmentTarget"
                "deviceAndAppManagementAssignmentFilterId" = if ($AssignmentFilter -ne $null) { $AssignmentFilter.id } else { $null }
                "deviceAndAppManagementAssignmentFilterType" = if ($AssignmentFilter -ne $null) { $FilterMode } else { "none" }
            } 

            # Construct table for Win32 app assignment body
            $Win32AppAssignmentBody = [ordered]@{
                "@odata.type" = "#microsoft.graph.mobileAppAssignment"
                "intent" = $Intent
                "source" = "direct"
                "target" = $TargetAssignment
            }
            $SettingsTable = @{
                "@odata.type" = "#microsoft.graph.win32LobAppAssignmentSettings"
                "notifications" = $Notification
                "restartSettings" = $null
                "deliveryOptimizationPriority" = $DeliveryOptimizationPriority
                "installTimeSettings" = $null
            }
            $Win32AppAssignmentBody.Add("settings", $SettingsTable)

            # Amend installTimeSettings property if Available parameter is specified
            if (($PSBoundParameters["AvailableTime"]) -and (-not($PSBoundParameters["DeadlineTime"]))) {
                $Win32AppAssignmentBody.settings.installTimeSettings = @{
                    "useLocalTime" = $UseLocalTime
                    "startDateTime" = (ConvertTo-JSONDate -InputObject $AvailableTime)
                    "deadlineDateTime" = $null
                }
            }

            # Amend installTimeSettings property if Deadline parameter is specified
            if (($PSBoundParameters["DeadlineTime"]) -and (-not($PSBoundParameters["AvailableTime"]))) {
                $Win32AppAssignmentBody.settings.installTimeSettings = @{
                    "useLocalTime" = $UseLocalTime
                    "startDateTime" = $null
                    "deadlineDateTime" = (ConvertTo-JSONDate -InputObject $DeadlineTime)
                }
            }

            # Amend installTimeSettings property if Available and Deadline parameter is specified
            if (($PSBoundParameters["AvailableTime"]) -and ($PSBoundParameters["DeadlineTime"])) {
                $Win32AppAssignmentBody.settings.installTimeSettings = @{
                    "useLocalTime" = $UseLocalTime
                    "startDateTime" = (ConvertTo-JSONDate -InputObject $AvailableTime)
                    "deadlineDateTime" = (ConvertTo-JSONDate -InputObject $DeadlineTime)
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

            $DuplicateAssignment = Test-IntuneWin32AppAssignment -ID $Win32AppID -Target "AllDevices"
            if ($DuplicateAssignment -eq $false) {
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
            Write-Warning -Message "Query for Win32 app returned an empty result, no apps matching the specified search criteria with ID '$($ID)' was found"
        }
    }
}
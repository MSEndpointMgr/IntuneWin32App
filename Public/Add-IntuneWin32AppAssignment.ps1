function Add-IntuneWin32AppAssignment {
    <#
    .SYNOPSIS
        Add an assignment to a Win32 app.

    .DESCRIPTION
        Add an assignment to a Win32 app.

    .PARAMETER TenantName
        Specify the tenant name, e.g. domain.onmicrosoft.com.

    .PARAMETER DisplayName
        Specify the display name for a Win32 application.

    .PARAMETER ID
        Specify the ID for a Win32 application.

    .PARAMETER Target
        Specify the target of the assignment, either AllUsers, AllDevices or Group.

    .PARAMETER Intent
        Specify the intent of the assignment, either required or available.

    .PARAMETER GroupID
        Specify the ID for an Azure AD group.

    .PARAMETER Notification
        Specify the notification setting for the assignment of the Win32 app.

    .PARAMETER Available
        Specify a date time object for the availability of the assignment.

    .PARAMETER Deadline
        Specify a date time object for the deadline of the assignment.

    .PARAMETER UseLocalTime
        Specify to use either UTC of device local time for the assignment, set to 'True' for device local time and 'False' for UTC.

    .PARAMETER DeliveryOptimizationPriority
        Specify to download content in the background using default value of 'notConfigured', or set to download in foreground using 'foreground'.

    .PARAMETER ApplicationID
        Specify the Application ID of the app registration in Azure AD. By default, the script will attempt to use well known Microsoft Intune PowerShell app registration.

    .PARAMETER PromptBehavior
        Set the prompt behavior when acquiring a token.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-01-04
        Updated:     2020-06-08

        Version history:
        1.0.0 - (2020-01-04) Function created
        1.0.1 - (2020-04-29) Added support for AllDevices target assignment type
        1.0.2 - (2020-06-08) Added support for Available and Deadline settings, device local time and Delivery Optimization settings of the assignment
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, ParameterSetName = "DisplayName", HelpMessage = "Specify the tenant name, e.g. domain.onmicrosoft.com.")]
        [parameter(Mandatory = $true, ParameterSetName = "ID")]
        [ValidateNotNullOrEmpty()]
        [string]$TenantName,

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
        [ValidateSet("required", "available")]
        [string]$Intent = "available",

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
        [datetime]$Available,

        [parameter(Mandatory = $false, ParameterSetName = "DisplayName", HelpMessage = "Specify a date time object for the deadline of the assignment.")]
        [parameter(Mandatory = $false, ParameterSetName = "ID")]
        [ValidateNotNullOrEmpty()]
        [datetime]$Deadline,

        [parameter(Mandatory = $false, ParameterSetName = "DisplayName", HelpMessage = "Specify to use either UTC of device local time for the assignment, set to 'True' for device local time and 'False' for UTC.")]
        [parameter(Mandatory = $false, ParameterSetName = "ID")]
        [ValidateNotNullOrEmpty()]
        [bool]$UseLocalTime = $false,

        [parameter(Mandatory = $false, ParameterSetName = "DisplayName", HelpMessage = "Specify to download content in the background using default value of 'notConfigured', or set to download in foreground using 'foreground'.")]
        [parameter(Mandatory = $false, ParameterSetName = "ID")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("notConfigured", "foreground")]
        [string]$DeliveryOptimizationPriority = "notConfigured",
        
        [parameter(Mandatory = $false, ParameterSetName = "DisplayName", HelpMessage = "Specify the Application ID of the app registration in Azure AD. By default, the script will attempt to use well known Microsoft Intune PowerShell app registration.")]
        [parameter(Mandatory = $false, ParameterSetName = "ID")]
        [ValidateNotNullOrEmpty()]
        [string]$ApplicationID = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547",
    
        [parameter(Mandatory = $false, ParameterSetName = "DisplayName", HelpMessage = "Set the prompt behavior when acquiring a token.")]
        [parameter(Mandatory = $false, ParameterSetName = "ID")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Auto", "Always", "Never", "RefreshSession")]
        [string]$PromptBehavior = "Auto"        
    )
    Begin {
        # Ensure required auth token exists or retrieve a new one
        Get-AuthToken -TenantName $TenantName -ApplicationID $ApplicationID -PromptBehavior $PromptBehavior

        # Validate group identifier is passed as input if target is set to Group
        if ($Target -like "Group") {
            if (-not($PSBoundParameters["GroupID"])) {
                Write-Warning -Message "Validation failed for parameter input, target set to Group but GroupID parameter was not specified"; break
            }
        }

        # Validate that Available parameter input datetime object is in the past if the Deadline parameter is not passed on the command line
        if ($PSBoundParameters["Available"]) {
            if (-not($PSBoundParameters["Deadline"])) {
                if ($Available -gt (Get-Date).AddDays(-1)) {
                    Write-Warning -Message "Validation failed for parameter input, available date time needs to be before the current used 'as soon as possible' deadline date and time, with a offset of 1 day"; break
                }
            }
        }

        # Validate that Deadline parameter input datetime object is in the future if the Available parameter is not passed on the command line
        if ($PSBoundParameters["Deadline"]) {
            if (-not($PSBoundParameters["Available"])) {
                if ($Deadline -lt (Get-Date)) {
                    Write-Warning -Message "Validation failed for parameter input, deadline date time needs to be after the current used 'as soon as possible' available date and time"; break
                }
            }
        }
    }
    Process {
        switch ($PSCmdlet.ParameterSetName) {
            "DisplayName" {
                Write-Verbose -Message "Attempting to retrieve all win32LobApp mobileApps type resources to determine ID of Win32 app with display name: $($DisplayName)"
                $Win32MobileApps = (Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps?`$filter=isof('microsoft.graph.win32LobApp')" -Method "GET").value
                if ($Win32MobileApps.Count -ge 1) {
                    $Win32MobileApp = $Win32MobileApps | Where-Object { $_.displayName -like "$($DisplayName)" }
                    if ($Win32MobileApp -ne $null) {
                        if ($Win32MobileApp.Count -eq 1) {
                            Write-Verbose -Message "Querying for Win32 app using ID: $($Win32MobileApp.id)"
                            $Win32App = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32MobileApp.id)" -Method "GET"
                            $Win32AppID = $Win32App.id
                        }
                        else {
                            Write-Verbose -Message "Multiple Win32 apps was returned after filtering for display name, please refine the input parameters"
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
                    }                    
                }
                "AllDevices" {
                    $TargetAssignment = @{
                        "@odata.type" = "#microsoft.graph.allDevicesAssignmentTarget"
                    }                    
                }
                "Group" {
                    $TargetAssignment = @{
                        "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
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

            #
            ## Placeholder for handling additional restartSettings if apps restart behavior is set to baseOnReturnCode
            if ($Win32App.installExperience.deviceRestartBehavior -like "basedOnReturnCode") {
                # Configure additional settings, if specified...
            }
            #

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
        else {
            Write-Warning -Message "Unable to determine the Win32 app identification for assignment"
        }
    }
}
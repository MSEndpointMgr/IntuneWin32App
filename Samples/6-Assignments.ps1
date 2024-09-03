# Get Azure AD group ObjectId property using AzureAD module
Connect-AzureAD
$GroupID = Get-AzureADGroup -SearchString "Group Name" | Select-Object -ExpandProperty "ObjectId"


# Get Win32 app ID using IntuneWin32App module
$Win32AppID = Get-IntuneWin32App -DisplayName "7-Zip 19.00 (x64 edition)" -Verbose | Select-Object -ExpandProperty "id"


# Create a group based include assignment
$AssignmentArgs = @{
    "Include" = $true
    "ID" = $Win32AppID
    "GroupID" = "efd0b26d-0713-4397-b9fe-2e9b5d916a67"
    "Intent" = "required" #available, uninstall
    "Verbose" = $true
}
Add-IntuneWin32AppAssignmentGroup @AssignmentArgs


# Create a group based include assignment with additional configuration
# AutoUpdateSupersededApps only for Intent Available
$AssignmentArgs = @{
    "Include" = $true
    "ID" = $Win32AppID
    "GroupID" = $GroupID
    "Intent" = "available" #required, uninstall
    "Notification" = "hideAll"
    "AvailableTime" = (Get-Date).AddHours(1)
    "DeadlineTime" = (Get-Date).AddDays(1)
    "UseLocalTime" = $true
    "DeliveryOptimizationPriority" = "foreground"
    "EnableRestartGracePeriod" = $true
    "RestartNotificationSnooze" = 220
    "Verbose" = $true
    "AutoUpdateSupersededApps" = "enabled"
}
Add-IntuneWin32AppAssignmentGroup @AssignmentArgs


# Clear all assignments for a Win32 app
Remove-IntuneWin32AppAssignment -ID $Win32AppID -Verbose


# Create a group based exclude assignment
$AssignmentArgs = @{
    "Exclude" = $true
    "ID" = $Win32AppID
    "GroupID" = $GroupID
    "Intent" = "required" #available, uninstall
    "Verbose" = $true
}
Add-IntuneWin32AppAssignmentGroup @AssignmentArgs


# Add an 'All Devices' assignment
$AssignmentArgs = @{
    "ID" = $Win32AppID
    "Intent" = "required" #available, uninstall
    "Verbose" = $true
}
Add-IntuneWin32AppAssignmentAllDevices @AssignmentArgs


# Add an 'All Devices' assignment with additional configuration
# AutoUpdateSupersededApps only for Intent Available
$AssignmentArgs = @{
    "ID" = $Win32AppID
    "Intent" = "available" #required, uninstall
    "Notification" = "hideAll"
    "AvailableTime" = (Get-Date).AddHours(1)
    "DeadlineTime" = (Get-Date).AddDays(1)
    "UseLocalTime" = $true
    "DeliveryOptimizationPriority" = "foreground"
    "EnableRestartGracePeriod" = $true
    "RestartNotificationSnooze" = 220
    "Verbose" = $true
    "AutoUpdateSupersededApps" = "enabled"
}
Add-IntuneWin32AppAssignmentAllDevices @AssignmentArgs


# Add an 'All Users' assignment
$AssignmentArgs = @{
    "ID" = $Win32AppID
    "Intent" = "required" #available, uninstall
    "Verbose" = $true
}
Add-IntuneWin32AppAssignmentAllUsers @AssignmentArgs


# Add an 'All Users' assignment with additional configuration
# AutoUpdateSupersededApps only for Intent Available
$AssignmentArgs = @{
    "ID" = $Win32AppID
    "Intent" = "available" #required, uninstall
    "Notification" = "hideAll"
    "AvailableTime" = (Get-Date).AddHours(1)
    "DeadlineTime" = (Get-Date).AddDays(1)
    "UseLocalTime" = $true
    "DeliveryOptimizationPriority" = "foreground"
    "EnableRestartGracePeriod" = $true
    "RestartNotificationSnooze" = 220
    "Verbose" = $true
    "AutoUpdateSupersededApps" = "enabled"
}
Add-IntuneWin32AppAssignmentAllUsers @AssignmentArgs
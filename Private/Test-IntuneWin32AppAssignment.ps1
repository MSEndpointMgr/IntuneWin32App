function Test-IntuneWin32AppAssignment {
    <#
    .SYNOPSIS
        Test the presence of an existing assignment type for a Win32 app.

    .DESCRIPTION
        Test the presence of an existing assignment type for a Win32 app. An assignment is considered a duplicate when the same target
        (All Devices, All Users or the same group) already exists with the same intent. The same group can be used with different intents,
        e.g. included for required and excluded for uninstall.

    .PARAMETER ID
        Specify the ID of the Win32 app.

    .PARAMETER Target
        Specify the target type of the assignment, AllDevices, AllUsers or Group.

    .PARAMETER GroupID
        Specify the ID of the group, required when Target is Group.

    .PARAMETER Intent
        Specify the intent of the assignment, either required, available or uninstall.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-09-21
        Updated:     2026-11-03

        Version history:
        1.0.0 - (2020-09-21) Function created
        1.0.1 - (2026-11-03) Fixed existing assignments never being detected, since the response is already unwrapped from the value property.
                             Intent is now taken into account so the same group can be used with different intents (#76, #85, #140).
    #>
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the ID of the Win32 app.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID,

        [parameter(Mandatory = $true, HelpMessage = "Specify the target type of the assignment, AllDevices, AllUsers or Group.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("AllDevices", "AllUsers", "Group")]
        [string]$Target,

        [parameter(Mandatory = $false, HelpMessage = "Specify the ID of the group, required when Target is Group.")]
        [string]$GroupID,

        [parameter(Mandatory = $false, HelpMessage = "Specify the intent of the assignment, either required, available or uninstall.")]
        [string]$Intent
    )
    Process {
        Write-Verbose -Message "Retrieving any existing Win32 app assignments to validate existing assignments for duplicate resources"
        $Win32AppAssignments = @(Invoke-MSGraphOperation -Get -APIVersion "Beta" -Resource "deviceAppManagement/mobileApps/$($ID)/assignments" | Where-Object { $null -ne $_ })
        if ($Win32AppAssignments.Count -eq 0) {
            Write-Verbose -Message "No existing assignments detected, skipping assignment validation for existence of target type: $($Target)"
            return $false
        }
        Write-Verbose -Message "Detected count of '$($Win32AppAssignments.Count)' existing assignments, processing each item for validation"

        foreach ($Win32AppAssignment in $Win32AppAssignments) {
            if ((-not([string]::IsNullOrEmpty($Intent))) -and ($Win32AppAssignment.intent -ne $Intent)) {
                continue
            }

            $TargetType = $Win32AppAssignment.target.'@odata.type'
            switch ($Target) {
                "Group" {
                    $IsMatch = ($TargetType -in @("#microsoft.graph.groupAssignmentTarget", "#microsoft.graph.exclusionGroupAssignmentTarget")) -and ($Win32AppAssignment.target.groupId -eq $GroupID)
                }
                "AllDevices" {
                    $IsMatch = ($TargetType -eq "#microsoft.graph.allDevicesAssignmentTarget")
                }
                "AllUsers" {
                    $IsMatch = ($TargetType -eq "#microsoft.graph.allLicensedUsersAssignmentTarget")
                }
            }

            if ($IsMatch) {
                Write-Warning -Message "Win32 app assignment with id '$($Win32AppAssignment.id)' of target type '$($Target)' and intent '$($Win32AppAssignment.intent)' already exists, duplicate assignments of this type is not permitted"
                return $true
            }
        }

        return $false
    }
}

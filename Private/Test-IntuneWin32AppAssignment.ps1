function Test-IntuneWin32AppAssignment {
    <#
    .SYNOPSIS
        Test the presence of an existing assignment type for a Win32 app.

    .DESCRIPTION
        Test the presence of an existing assignment type for a Win32 app.

    .PARAMETER ID
        Specify the ID of the Win32 app.

    .PARAMETER Target
        Specify the target type of the assignment, AllDevices, AllUsers or Group.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-09-21
        Updated:     2020-09-21

        Version history:
        1.0.0 - (2020-09-21) Function created
    #>    
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the ID of the Win32 app.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID,

        [parameter(Mandatory = $false, HelpMessage = "Specify the target type of the assignment, AllDevices, AllUsers or Group.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("AllDevices", "AllUsers", "Group")]
        [string]$Target
    )
    Process {
        # Handle initial value for duplicate assignment
        $DuplicateAssignmentDetected = $false

        try {
            Write-Verbose -Message "Retrieving any existing Win32 app assignments to validate existing assignments for duplicate resources"
            $Win32AppAssignments = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($ID)/assignments" -Method "GET" -ErrorAction Stop
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
                            if ($Win32AppAssignment.target.'@odata.type' -eq "#microsoft.graph.groupAssignmentTarget") {
                                if ($Win32AppAssignment.target.groupId -like $GroupID) {
                                    Write-Warning -Message "Win32 app assignment with id '$($Win32AppAssignment.id)' of target type '$($Target)' and GroupID '$($Win32AppAssignment.target.groupId)' already exists, duplicate assignments of this type is not permitted"
                                    $DuplicateAssignmentDetected = $true
                                }
                            }
                        }
                    }
                    default {
                        foreach ($Win32AppAssignment in $Win32AppAssignments.value) {
                            if ($Win32AppAssignment.target.'@odata.type' -match $TargetType) {
                                Write-Warning -Message "Win32 app assignment with id '$($Win32AppAssignment.id)' of target type '$($Target)' already exists, duplicate assignments of this type is not permitted"
                                $DuplicateAssignmentDetected = $true
                            }
                        }
                    }
                }
            }
            else {
                Write-Verbose -Message "Detected count of '$($Win32AppAssignmentsCount)', skipping assignment validation for existence of target type: $($Target)"
            }

            # Handle return value
            if ($DuplicateAssignmentDetected -eq $true) {
                return $true
            }
            else {
                return $false
            }
        }
        catch [System.Exception] {
            Write-Warning -Message "Failed to validate if Win32 app already has an existing assignment target type of '$($Target)'"
        }
    }
}
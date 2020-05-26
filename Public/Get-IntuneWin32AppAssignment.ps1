function Get-IntuneWin32AppAssignment {
    <#
    .SYNOPSIS
        Retrieve all assignments for a Win32 app.

    .DESCRIPTION
        Retrieve all assignments for a Win32 app.

    .PARAMETER TenantName
        Specify the tenant name, e.g. domain.onmicrosoft.com.

    .PARAMETER DisplayName
        Specify the display name for a Win32 application.

    .PARAMETER ID
        Specify the ID for a Win32 application.

    .PARAMETER GroupName
        Specify a group name to scope assignments targeted for that group.

    .PARAMETER ApplicationID
        Specify the Application ID of the app registration in Azure AD. By default, the script will attempt to use well known Microsoft Intune PowerShell app registration.

    .PARAMETER PromptBehavior
        Set the prompt behavior when acquiring a token.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-04-29
        Updated:     2020-04-29

        Version history:
        1.0.0 - (2020-04-29) Function created
        1.0.1 - (2020-05-26) Added new parameter GroupName to be able to retrieve assignments associated with a given group
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, ParameterSetName = "DisplayName", HelpMessage = "Specify the tenant name, e.g. domain.onmicrosoft.com.")]
        [parameter(Mandatory = $true, ParameterSetName = "ID")]
        [parameter(Mandatory = $true, ParameterSetName = "Group")]
        [ValidateNotNullOrEmpty()]
        [string]$TenantName,

        [parameter(Mandatory = $true, ParameterSetName = "DisplayName", HelpMessage = "Specify the display name for a Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [parameter(Mandatory = $true, ParameterSetName = "ID", HelpMessage = "Specify the ID for a Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID,

        [parameter(Mandatory = $true, ParameterSetName = "Group", HelpMessage = "Specify a group name to scope assignments targeted for that group.")]
        [ValidateNotNullOrEmpty()]
        [string]$GroupName,
        
        [parameter(Mandatory = $false, ParameterSetName = "DisplayName", HelpMessage = "Specify the Application ID of the app registration in Azure AD. By default, the script will attempt to use well known Microsoft Intune PowerShell app registration.")]
        [parameter(Mandatory = $false, ParameterSetName = "ID")]
        [parameter(Mandatory = $false, ParameterSetName = "Group")]
        [ValidateNotNullOrEmpty()]
        [string]$ApplicationID = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547",
    
        [parameter(Mandatory = $false, ParameterSetName = "DisplayName", HelpMessage = "Set the prompt behavior when acquiring a token.")]
        [parameter(Mandatory = $false, ParameterSetName = "ID")]
        [parameter(Mandatory = $false, ParameterSetName = "Group")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Auto", "Always", "Never", "RefreshSession")]
        [string]$PromptBehavior = "Auto"        
    )
    Begin {
        # Ensure required auth token exists or retrieve a new one
        Get-AuthToken -TenantName $TenantName -ApplicationID $ApplicationID -PromptBehavior $PromptBehavior
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
            "Group" {
                $MobileApps = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps" -Method "GET"
                if ($MobileApps.value.Count -ge 1) {
                    $Win32MobileApps = $MobileApps.value | Where-Object { $_.'@odata.type' -like "#microsoft.graph.win32LobApp" }
                    if ($Win32MobileApps -ne $null) {
                        $Win32MobileAppsList = New-Object -TypeName System.Collections.ArrayList
                        foreach ($Win32MobileApp in $Win32MobileApps) {
                            $Win32MobileAppsList.Add($Win32MobileApp) | Out-Null
                        }
                    }
                    else {
                        Write-Warning -Message "Query for Win32 apps returned empty a result, no apps matching type 'win32LobApp' was found in tenant"
                    }
                }
            }
        }

        switch ($PSCmdlet.ParameterSetName) {
            "Group" {
                foreach ($Win32MobileApp in $Win32MobileAppsList) {
                    try {
                        # Attempt to call Graph and retrieve all assignments for each Win32 app
                        $Win32AppAssignmentResponse = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32MobileApp.id)/assignments" -Method "GET" -ErrorAction Stop
                        if ($Win32AppAssignmentResponse.value -ne $null) {
                            foreach ($Win32AppAssignment in $Win32AppAssignmentResponse.value) {
                                if ($Win32AppAssignment.target.'@odata.type' -like "*groupAssignmentTarget") {
                                    try {
                                        # Retrieve group name from given group id
                                        $AzureADGroupResponse = Invoke-AzureADGraphRequest -Resource "groups/$($Win32AppAssignment.target.groupId)" -Method "GET"
                                        if ($AzureADGroupResponse.displayName -like "*$($GroupName)*") {
                                            Write-Verbose -Message "Win32 app assignment '$($Win32AppAssignment.id)' for app '$($Win32MobileApp.displayName)' matched group name: $($GroupName)"

                                            # Create a custom object for return value
                                            $PSObject = [PSCustomObject]@{
                                                AppName = $Win32MobileApp.displayName
                                                GroupID = $Win32AppAssignment.target.groupId
                                                GroupName = $AzureADGroupResponse.displayName
                                                Intent = $Win32AppAssignment.intent
                                            }
                                            Write-Output -InputObject $PSObject
                                        }
                                    }
                                    catch [System.Exception] {
                                        Write-Warning -Message "An error occurred while resolving groupId for assignment with ID: $($Win32AppAssignment.id). Error message: $($_.Exception.Message)"
                                    }
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
            }
            default {
                if (-not([string]::IsNullOrEmpty($Win32AppID))) {
                    try {
                        # Attempt to call Graph and retrieve all assignments for Win32 app
                        $Win32AppAssignmentResponse = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32AppID)/assignments" -Method "GET" -ErrorAction Stop
                        if ($Win32AppAssignmentResponse.value -ne $null) {
                            foreach ($Win32AppAssignment in $Win32AppAssignmentResponse.value) {
                                Write-Verbose -Message "Successfully retrieved Win32 app assignment with ID: $($Win32AppAssignment.id)"
                                Write-Output -InputObject $Win32AppAssignment
                            }
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
    }
}
function Add-IntuneWin32AppDependency {
<#
    .SYNOPSIS
        Add dependency configuration to an existing Win32 application.

    .DESCRIPTION
        Add dependency configuration to an existing Win32 application.

    .PARAMETER ID
        Specify the ID for an existing Win32 application where the dependency will be configured.

    .PARAMETER Dependency
        Provide an array of a single or multiple OrderedDictionary objects created with New-IntuneWin32AppDependency function.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2021-08-31
        Updated:     2021-08-31

        Version history:
        1.0.0 - (2021-08-31) Function created
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the ID for an existing Win32 application where supersedence will be configured.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID,
        
        [parameter(Mandatory = $true, HelpMessage = "Provide an array of a single or multiple OrderedDictionary objects created with New-IntuneWin32AppDependency function.")]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.OrderedDictionary[]]$Dependency
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

        # Validate maximum number of dependency configuration tables
        if ($Dependency.Count -gt 100) {
            Write-Warning -Message "Maximum allowed number of dependency objects '100' detected, actual count passed as input: $($Dependency.Count)"; break
        }
    }
    Process {
        # Retrieve Win32 app by ID from parameter input
        Write-Verbose -Message "Querying for Win32 app using ID: $($ID)"
        $Win32App = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($ID)" -Method "GET"
        if ($Win32App -ne $null) {
            $Win32AppID = $Win32App.id

            # Check for existing relations for Win32 app, supersedence and dependency configurations cannot co-exist currently
            $Win32AppSupersedenceExistence = Get-IntuneWin32AppRelationExistence -ID $Win32AppID -Type "Supersedence"
            if ($Win32AppSupersedenceExistence -eq $false) {
                # Validate that Win32 app where dependency is configured, is not passed in $Dependency variable to prevent an app depending on itself
                if ($Win32AppID -notin $Dependency.targetId) {
                    $Win32AppRelationships = [ordered]@{
                        "relationships" = @($Dependency)
                    }

                    try {
                        # Attempt to call Graph and configure dependency for Win32 app
                        Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32AppID)/updateRelationships" -Method "POST" -Body ($Win32AppRelationships | ConvertTo-Json) -ErrorAction Stop
                    }
                    catch [System.Exception] {
                        Write-Warning -Message "An error occurred while configuring dependency for Win32 app: $($Win32AppID). Error message: $($_.Exception.Message)"
                    }
                }
                else {
                    $DependencyItems = -join@($Dependency.targetId, ", ")
                    Write-Warning -Message "A Win32 app cannot be used to dependend on itself, please specify a valid array or single object for dependency"
                    Write-Warning -Message "Win32 app with ID '$($Win32AppID)' is set as parent for dependency configuration, and was also found in child items: $($DependencyItems)"
                }
            }
            else {
                Write-Warning -Message "Existing supersedence relation configuration exists for Win32 app, dependency is not allowed to be configured at this point"
            }
        }
        else {
            Write-Warning -Message "Query for Win32 app returned an empty result, no apps matching the specified search criteria with ID '$($ID)' was found"
        }
    }
}
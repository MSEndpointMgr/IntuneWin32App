function Get-IntuneWin32AppRelationship {
    <#
    .SYNOPSIS
        Retrieve any existing supersedence and dependency (relations) configuration from an existing Win32 application.

    .DESCRIPTION
        Retrieve any existing supersedence and dependency (relations) configuration from an existing Win32 application.

    .PARAMETER ID
        Specify the ID for an existing Win32 application to retrieve relation configuration from.

    .PARAMETER Type
        Specify the type of relationship.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2021-04-02
        Updated:     2023-10-30

        Version history:
        1.0.0 - (2021-04-02) Function created
        1.0.1 - (2021-08-31) Updated to use new authentication header
        1.0.2 - (2023-09-04) Renamed function, was not named correctly. Added Type parameter and updated with Test-AccessToken.
        1.0.3 - (2023-10-30) Convert from private to public function and rename to Get-IntuneWin32AppRelationship
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the ID for an existing Win32 application to retrieve relation configuration from.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID,

        [Parameter(Mandatory = $true, HelpMessage = "Specify the type of relationship.")]
        [ValidateSet("Dependency", "Supersedence")]
        [string]$Type
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
            else {
                Write-Verbose -Message "Current authentication token expires in (minutes): $($TokenLifeTime)"
            }
        }

        # Set script variable for error action preference
        $ErrorActionPreference = "Stop"
    }
    Process {
        try {
            # Define static variables
            $RelationshipExistence = $false

            # Attempt to call Graph and retrieve supersedence configuration for Win32 app
            $Win32AppRelationshipResponse = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($ID)/relationships" -Method "GET" -ErrorAction "Stop"

            # Switch depending on input type
            if ($Win32AppRelationshipResponse.value -ne $null) {
                switch ($Type) {
                    "Dependency" {
                        if ($Win32AppRelationshipResponse.value.'@odata.type' -like "#microsoft.graph.mobileAppDependency") {
                            $RelationshipExistence = $true
                        }
                    }
                    "Supersedence" {
                        if ($Win32AppRelationshipResponse.value.'@odata.type' -like "#microsoft.graph.mobileAppSupersedence") {
                            $RelationshipExistence = $true
                        }
                    }
                }
            }

            # Handle return value
            return $RelationshipExistence
        }
        catch [System.Exception] {
            Write-Warning -Message "An error occurred while retrieving relationships configuration for Win32 app: $($ID). Error message: $($_.Exception.Message)"
        }
    }
}
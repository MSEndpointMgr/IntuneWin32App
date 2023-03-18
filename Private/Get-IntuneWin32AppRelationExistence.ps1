function Get-IntuneWin32AppRelation {
    <#
    .SYNOPSIS
        Retrieve any existing supersedence and dependency (relations) configuration from an existing Win32 application.

    .DESCRIPTION
        Retrieve any existing supersedence and dependency (relations) configuration from an existing Win32 application.

    .PARAMETER ID
        Specify the ID for an existing Win32 application to retrieve relation configuration from.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2021-04-02
        Updated:     2021-08-31

        Version history:
        1.0.0 - (2021-04-02) Function created
        1.0.1 - (2021-08-31) Updated to use new authentication header
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the ID for an existing Win32 application to retrieve relation configuration from.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID
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
    }
    Process {
        try {
            # Define static variables
            $RelationExistence = $false

            # Attempt to call Graph and retrieve supersedence configuration for Win32 app
            $Win32AppRelationsResponse = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($ID)/relationships" -Method "GET" -ErrorAction Stop

            # Switch depending on input type
            if ($Win32AppRelationsResponse.value -ne $null) {
                switch ($Type) {
                    "Dependency" {
                        if ($Win32AppRelationsResponse.value.'@odata.type' -like "#microsoft.graph.mobileAppDependency") {
                            $RelationExistence = $true
                        }
                    }
                    "Supersedence" {
                        if ($Win32AppRelationsResponse.value.'@odata.type' -like "#microsoft.graph.mobileAppSupersedence") {
                            $RelationExistence = $true
                        }
                    }
                }
            }

            # Handle return value
            return $RelationExistence

        }
        catch [System.Exception] {
            Write-Warning -Message "An error occurred while retrieving supersedence configuration for Win32 app: $($ID). Error message: $($_.Exception.Message)"
        }
    }
}
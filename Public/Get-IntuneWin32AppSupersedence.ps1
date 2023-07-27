function Get-IntuneWin32AppSupersedence {
    <#
    .SYNOPSIS
        Retrieve supersedence configuration from an existing Win32 application.

    .DESCRIPTION
        Retrieve supersedence configuration from an existing Win32 application.

    .PARAMETER ID
        Specify the ID for an existing Win32 application to retrieve supersedence configuration.

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
        [parameter(Mandatory = $true, HelpMessage = "Specify the ID for an existing Win32 application to retrieve supersedence configuration.")]
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
        # Retrieve Win32 app by ID from parameter input
        Write-Verbose -Message "Querying for Win32 app using ID: $($ID)"
        $Win32App = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($ID)" -Method "GET"
        if ($Win32App -ne $null) {
            $Win32AppID = $Win32App.id

            try {
                # Attempt to call Graph and retrieve supersedence configuration for Win32 app
                $Win32AppRelationsResponse = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32AppID)/relationships" -Method "GET" -ErrorAction Stop

                # Handle return value
                $Win32AppRelationsResponse.value | Where-Object { $_.'@odata.type' -like "#microsoft.graph.mobileAppSupersedence" }
            }
            catch [System.Exception] {
                Write-Warning -Message "An error occurred while retrieving supersedence configuration for Win32 app: $($Win32AppID). Error message: $($_.Exception.Message)"
            }
        }
        else {
            Write-Warning -Message "Query for Win32 app returned an empty result, no apps matching the specified search criteria with ID '$($ID)' was found"
        }
    }
}
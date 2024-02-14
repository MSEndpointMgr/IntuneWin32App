function Get-IntuneWin32AppSupersedence {
    <#
    .SYNOPSIS
        Retrieve supersedence configuration from an existing Win32 application.

    .DESCRIPTION
        Retrieve supersedence configuration from an existing Win32 application.

    .PARAMETER ID
        Specify the ID for an existing Win32 application to retrieve supersedence configuration.

    .PARAMETER CHILDONLY
        Return only supersedence children ignoring parent relationships

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2021-04-02
        Updated:     2023-09-04

        Version history:
        1.0.0 - (2021-04-02) Function created
        1.0.1 - (2021-08-31) Updated to use new authentication header
        1.0.2 - (2023-09-04) Updated with Test-AccessToken function
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the ID for an existing Win32 application to retrieve supersedence configuration.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID,

        [parameter(Mandatory = $false, HelpMessage = "Return on child supersedences")]
        [ValidateNotNullOrEmpty()]
        [switch] $ChildOnly
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
    }
    Process {
        # Retrieve Win32 app by ID from parameter input
        Write-Verbose -Message "Querying for Win32 app using ID: $($ID)"
        $Win32App = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($ID)" -Method "GET"
        if ($null -ne $Win32App) {
            $Win32AppID = $Win32App.id

            try {
                # Attempt to call Graph and retrieve supersedence configuration for Win32 app
                $Win32AppRelationsResponse = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32AppID)/relationships" -Method "GET" -ErrorAction Stop
                $Win32AppRelationsResponse_Return = @()
                # Handle return value
                if ($null -ne $Win32AppRelationsResponse.value) {
                    $Win32AppRelationsResponse_Return = $Win32AppRelationsResponse.value | WHere-Object { $_."@odata.type" -like "#microsoft.graph.mobileAppSupersedence" }
                }
                if($ChildOnly) {
                    $Win32AppRelationsResponse_Return = $Win32AppRelationsResponse_Return | Where-Object { $_.targetType -eq "child"}
                }
                #Return as an array of hash tables rather than a PSCustomObject
                return @(ConvertTo-Hashtable $Win32AppRelationsResponse_Return)
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
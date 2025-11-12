function Set-IntuneWin32App {
    <#
    .SYNOPSIS
        Update an existing Win32 application object in Intune.

    .DESCRIPTION
        Update an existing Win32 application object in Intune, for instance update with a new display name, change the description or app version information.

    .PARAMETER ID
        Specify the ID of the targeted Win32 application where changes will be applied.

    .PARAMETER DisplayName
        Specify a new display name for the Win32 application.

    .PARAMETER Description
        Specify a new description for the Win32 application.

    .PARAMETER Publisher
        Specify a new publisher name for the Win32 application.

    .PARAMETER AppVersion
        Specify a new app version for the Win32 application.

    .PARAMETER Developer
        Specify a new developer name for the Win32 application.

    .PARAMETER Owner
        Specify a new owner property for the Win32 application.

    .PARAMETER Notes
        Specify a new notes property for the Win32 application.

    .PARAMETER InformationURL
        Specify a new information URL for the Win32 application.

    .PARAMETER PrivacyURL
        Specify a new privacy URL for the Win32 application.

    .PARAMETER CompanyPortalFeaturedApp
        Specify whether to have the Win32 application featured in Company Portal or not.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2023-01-25
        Updated:     2023-09-04

        Version history:
        1.0.0 - (2023-01-25) Function created
        1.0.1 - (2023-03-17) Added AllowAvailableUninstall parameter switch.
        1.0.2 - (2023-09-04) Updated with Test-AccessToken function
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the ID of the targeted Win32 application where changes will be applied.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID,

        [parameter(Mandatory = $false, HelpMessage = "Specify a new display name for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [parameter(Mandatory = $false, HelpMessage = "Specify a new description for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$Description,

        [parameter(Mandatory = $false, HelpMessage = "Specify a new publisher name for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$Publisher,

        [parameter(Mandatory = $false, HelpMessage = "Specify a new app version for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$AppVersion,

        [parameter(Mandatory = $false, HelpMessage = "Specify a new developer name for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$Developer,

        [parameter(Mandatory = $false, HelpMessage = "Specify a new owner property for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$Owner,

        [parameter(Mandatory = $false, HelpMessage = "Specify a new notes property for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$Notes,

        [parameter(Mandatory = $false, HelpMessage = "Specify a new information URL for the Win32 application.")]
        [ValidatePattern("(http[s]?|[s]?ftp[s]?)(:\/\/)([^\s,]+)")]
        [string]$InformationURL,

        [parameter(Mandatory = $false, HelpMessage = "Specify a new privacy URL for the Win32 application.")]
        [ValidatePattern("(http[s]?|[s]?ftp[s]?)(:\/\/)([^\s,]+)")]
        [string]$PrivacyURL,

        [parameter(Mandatory = $false, HelpMessage = "Specify whether to have the Win32 application featured in Company Portal or not.")]
        [bool]$CompanyPortalFeaturedApp,

        [parameter(Mandatory = $false, HelpMessage = "Specify whether to allow the Win32 application to be uninstalled from the Company Portal app when assigned as available.")]
        [bool]$AllowAvailableUninstall
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
        if ($Win32App -ne $null) {
            $Win32AppID = $Win32App.id

            # Construct required part of request body for PATCH operation
            $Win32AppBody = @{
                "@odata.type" = "#microsoft.graph.win32LobApp"
            }

            # Dynamically extend request body depending on what parameters are passed on the command line
            if ($PSBoundParameters["DisplayName"]) {
                $Win32AppBody.Add("displayName", $DisplayName)
            }
            if ($PSBoundParameters["Description"]) {
                $Win32AppBody.Add("description", $Description)
            }
            if ($PSBoundParameters["Publisher"]) {
                $Win32AppBody.Add("publisher", $Publisher)
            }
            if ($PSBoundParameters["AppVersion"]) {
                $Win32AppBody.Add("displayVersion", $AppVersion)
            }
            if ($PSBoundParameters["Developer"]) {
                $Win32AppBody.Add("developer", $Developer)
            }
            if ($PSBoundParameters["Owner"]) {
                $Win32AppBody.Add("owner", $Owner)
            }
            if ($PSBoundParameters["Notes"]) {
                $Win32AppBody.Add("notes", $Notes)
            }
            if ($PSBoundParameters["InformationURL"]) {
                $Win32AppBody.Add("informationUrl", $InformationURL)
            }
            if ($PSBoundParameters["PrivacyURL"]) {
                $Win32AppBody.Add("privacyInformationUrl", $PrivacyURL)
            }
            if ($PSBoundParameters["CompanyPortalFeaturedApp"]) {
                $Win32AppBody.Add("isFeatured", $CompanyPortalFeaturedApp)
            }
            if ($PSBoundParameters["AllowAvailableUninstall"]) {
                $Win32AppBody.Add("allowAvailableUninstall", $AllowAvailableUninstall)
            }

            try {
                # Attempt to call Graph and update Win32 app
                $Win32AppResponse = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32AppID)" -Method "PATCH" -Body ($Win32AppBody | ConvertTo-Json) -ContentType "application/json" -ErrorAction "Stop"
                Write-Verbose -Message "Successfully updated Win32 app object with ID: $($Win32AppID)"
            }
            catch [System.Exception] {
                Write-Warning -Message "An error occurred while update Win32 app object. Error message: $($_.Exception.Message)"
                throw
            }
        }
        else {
            Write-Warning -Message "Query for Win32 app returned an empty result, no apps matching the specified search criteria with ID '$($ID)' was found"
        }
    }
}
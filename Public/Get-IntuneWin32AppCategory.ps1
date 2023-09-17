function Get-IntuneWin32AppCategory {
    <#
    .SYNOPSIS
        Get all available application categories.

    .DESCRIPTION
        Use this function to retrieve a list of available categories, or to check if a category exist by it's display name.

    .PARAMETER DisplayName
        Specify the display name of the category.

    .PARAMETER List
        Return all available categories.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2023-01-29
        Updated:     2023-09-04

        Version history:
        1.0.0 - (2023-01-29) Function created
        1.0.1 - (2023-09-04) Updated with Test-AccessToken function
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, ParameterSetName = "DisplayName", HelpMessage = "Specify the display name of the category.")]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [parameter(Mandatory = $true, ParameterSetName = "List", HelpMessage = "Return all available categories.")]
        [ValidateNotNullOrEmpty()]
        [switch]$List
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
        # Construct list for output of categories
        $Win32AppCategoryList = New-Object -TypeName "System.Collections.ArrayList"

        # Construct resource uri depending on parameter set name
        switch ($PSCmdlet.ParameterSetName) {
            "DisplayName" {
                $Resource = "mobileAppCategories?`$filter=displayName eq '$([System.Web.HttpUtility]::UrlEncode($DisplayName))'"
            }
            "List" {
                $Resource = "mobileAppCategories"
            }
        }

        try {
            # Invoke Graph API call to retrieve categories
            $Win32AppCategories = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource $Resource -Method "GET" -ErrorAction "Stop"
            if ($Win32AppCategories.value.Count -ge 1) {
                foreach ($Win32AppCategory in $Win32AppCategories.value) {
                    $PSObject = [PSCustomObject]@{
                        ID = $Win32AppCategory.id
                        DisplayName = $Win32AppCategory.displayName
                        LastModifiedDateTime = $Win32AppCategory.lastModifiedDateTime
                    }
                    $Win32AppCategoryList.Add($PSObject) | Out-Null
                }

                # Handle return value
                return $Win32AppCategoryList
            }
            else {
                switch ($PSCmdlet.ParameterSetName) {
                    "DisplayName" {
                        Write-Warning -Message "Could not find category with matching display name of '$($DisplayName)'"
                    }
                    "List" {
                        Write-Warning -Message "Empty response of categories from request"
                    }
                }
            }
        }
        catch [System.Exception] {
            Write-Warning -Message "An error occurred while retrieving categories. Error message: $($_.Exception.Message)"
        }
    }
}
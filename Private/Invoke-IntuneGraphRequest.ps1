function Invoke-IntuneGraphRequest {
    <#
    .SYNOPSIS
        Perform a specific call to Intune Graph API, either as GET, POST or PATCH methods.

    .DESCRIPTION
        Perform a specific call to Intune Graph API, either as GET, POST or PATCH methods.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-01-04
        Updated:     2020-08-31

        Version history:
        1.0.0 - (2020-01-04) Function created
        1.0.1 - (2020-04-29) Added support for DELETE operations
        1.0.2 - (2021-08-31) Updated to use new authentication header
        1.0.3 - (2022-10-02) Changed content type for requests to support UTF8
    #>    
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Beta", "v1.0")]
        [string]$APIVersion,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Resource,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("GET", "POST", "PATCH", "DELETE")]
        [string]$Method,

        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Object]$Body,

        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        #[string]$ContentType = "application/json"
        [string]$ContentType = "application/json; charset=utf-8"
    )
    try {
        # Construct full URI
        $GraphURI = "https://graph.microsoft.com/$($APIVersion)/deviceAppManagement/$($Resource)"
        Write-Verbose -Message "$($Method) $($GraphURI)"

        # Call Graph API and get JSON response
        switch ($Method) {
            "GET" {
                $GraphResponse = Invoke-RestMethod -Uri $GraphURI -Headers $Global:AuthenticationHeader -Method $Method -ErrorAction Stop -Verbose:$false
            }
            "POST" {
                $GraphResponse = Invoke-RestMethod -Uri $GraphURI -Headers $Global:AuthenticationHeader -Method $Method -Body $Body -ContentType $ContentType -ErrorAction Stop -Verbose:$false
            }
            "PATCH" {
                $GraphResponse = Invoke-RestMethod -Uri $GraphURI -Headers $Global:AuthenticationHeader -Method $Method -Body $Body -ContentType $ContentType -ErrorAction Stop -Verbose:$false
            }
            "DELETE" {
                $GraphResponse = Invoke-RestMethod -Uri $GraphURI -Headers $Global:AuthenticationHeader -Method $Method -ErrorAction Stop -Verbose:$false
            }
        }

        return $GraphResponse
    }
    catch [System.Exception] {
        # Construct stream reader for reading the response body from API call
        $ResponseBody = Get-ErrorResponseBody -Exception $_.Exception

        # Handle response output and error message
        Write-Output -InputObject "Response content:`n$ResponseBody"
        Write-Warning -Message "Request to $($GraphURI) failed with HTTP Status $($_.Exception.Response.StatusCode) and description: $($_.Exception.Response.StatusDescription)"
    }
}
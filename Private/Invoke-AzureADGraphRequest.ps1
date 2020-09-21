function Invoke-AzureADGraphRequest {
    <#
    .SYNOPSIS
        Perform a GET method call to Azure AD Graph API.

    .DESCRIPTION
        Perform a GET method call to Azure AD Graph API.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-05-26
        Updated:     2020-05-26

        Version history:
        1.0.0 - (2020-05-26) Function created
    #>    
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Resource,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("GET")]
        [string]$Method
    )
    try {
        # Construct full URI
        $GraphURI = "https://graph.microsoft.com/v1.0/$($Resource)"
        Write-Verbose -Message "$($Method) $($GraphURI)"

        # Call Graph API and get JSON response
        switch ($Method) {
            "GET" {
                $GraphResponse = Invoke-RestMethod -Uri $GraphURI -Headers $Global:AuthToken -Method $Method -ErrorAction Stop -Verbose:$false
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
function Invoke-AzureStorageBlobUploadFinalize {
    <#
    .SYNOPSIS
        Finalize upload of chunks of the .intunewin file into Azure Storage blob container.

    .DESCRIPTION
        Finalize upload of chunks of the .intunewin file into Azure Storage blob container.

        This is a modified function that was originally developed by Dave Falkus and is available here:
        https://github.com/microsoftgraph/powershell-intune-samples/blob/master/LOB_Application/Win32_Application_Add.ps1

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-01-04
        Updated:     2024-05-29

        Version history:
        1.0.0 - (2020-01-04) Function created
        1.0.1 - (2024-05-29) Added content-type header to the REST request to ensure correct handling of the request body (thanks to @tjgruber)
        1.0.2 - (2024-06-03) Added exception throwing on failure to support retry logic in the finalization process (thanks to @tjgruber)
    #>
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$StorageUri,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]$ChunkID
    )

    $Uri = "$($StorageUri)&comp=blocklist"

    $XML = '<?xml version="1.0" encoding="utf-8"?><BlockList>'

    foreach ($Chunk in $ChunkID) {
        $XML += "<Latest>$($Chunk)</Latest>"
    }

    $XML += '</BlockList>'

    $Headers = @{
        "content-type" = "text/plain; charset=UTF-8"
    }

    try {
        $WebResponse = Invoke-RestMethod -Uri $Uri -Method "Put" -Body $XML -Headers $Headers -ErrorAction Stop
        return $WebResponse
    } catch {
        Write-Warning -Message "Failed to finalize Azure Storage blob upload. Error message: $($_.Exception.Message)"
        throw $_
    }
}

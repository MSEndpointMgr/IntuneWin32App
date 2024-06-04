function Invoke-AzureStorageBlobUploadRenew {
    <#
    .SYNOPSIS
        Renew the SAS URI.

    .DESCRIPTION
        Renew the SAS URI.

        This is a modified function that was originally developed by Dave Falkus and is available here:
        https://github.com/microsoftgraph/powershell-intune-samples/blob/master/LOB_Application/Win32_Application_Add.ps1

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-01-04
        Updated:     2024-06-03

        Version history:
        1.0.0 - (2020-01-04) Function created
        1.0.1 - (2021-03-15) Fixed an issue where SAS Uri renewal wasn't working correctly
        1.0.2 - (2024-06-03) Added loop to check the status of the SAS URI renewal
    #>
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Resource
    )
    $RenewSASURIRequest = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "$($Resource)/renewUpload" -Method "POST" -Body "{}"

    # Loop to wait for the renewal process to complete and check the status
    $attempts = 0
    $maxAttempts = 3
    $waitTime = 5 # seconds

    while ($attempts -lt $maxAttempts) {
        $FilesProcessingRequest = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "$($Resource)" -Method "GET"
        if ($FilesProcessingRequest.uploadState -eq "azureStorageUriRenewalSuccess") {
            return $FilesProcessingRequest.azureStorageUri
        } elseif ($FilesProcessingRequest.uploadState -eq "azureStorageUriRenewalFailed") {
            throw "SAS Uri renewal failed"
        }
        $attempts++
        Start-Sleep -Seconds $waitTime
    }
    throw "SAS Uri renewal did not complete in the expected time"
}

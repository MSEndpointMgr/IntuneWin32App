function Invoke-AzureStorageBlobUpload {
    <#
    .SYNOPSIS
        Upload and commit .intunewin file into Azure Storage blob container.

    .DESCRIPTION
        Upload and commit .intunewin file into Azure Storage blob container.

        This is a modified function that was originally developed by Dave Falkus and is available here:
        https://github.com/microsoftgraph/powershell-intune-samples/blob/master/LOB_Application/Win32_Application_Add.ps1        

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-01-04
        Updated:     2022-09-03

        Version history:
        1.0.0 - (2020-01-04) Function created
        1.0.1 - (2020-09-20) Fixed an issue where the System.IO.BinaryReader wouldn't open a file path containing whitespaces
        1.0.2 - (2021-03-15) Fixed an issue where SAS Uri renewal wasn't working correctly
        1.0.3 - (2022-09-03) Added access token refresh functionality when a token is about to expire, to prevent uploads from failing due to an expire access token
    #>    
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$StorageUri,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Resource
    )
    $ChunkSizeInBytes = 1024l * 1024l * 6l;

    # Start the timer for SAS URI renewal
    $SASRenewalTimer = [System.Diagnostics.Stopwatch]::StartNew()

    # Find the file size and open the file
    $FileSize = (Get-Item -Path $FilePath).Length
    $ChunkCount = [System.Math]::Ceiling($FileSize / $ChunkSizeInBytes)
    $BinaryReader = New-Object -TypeName System.IO.BinaryReader([System.IO.File]::Open($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite))
    $Position = $BinaryReader.BaseStream.Seek(0, [System.IO.SeekOrigin]::Begin)

    # Upload each chunk and dheck whether a SAS URI renewal is required after each chunk is uploaded and renew if needed
    $ChunkIDs = @()
    for ($Chunk = 0; $Chunk -lt $ChunkCount; $Chunk++) {
        Write-Verbose -Message "SAS Uri renewal timer has elapsed for: $($SASRenewalTimer.Elapsed.Minutes) minute $($SASRenewalTimer.Elapsed.Seconds) seconds"

        # Refresh access token if about to expire
        $UTCDateTime = (Get-Date).ToUniversalTime()
        $TokenExpiresMinutes = ($Global:AccessToken.ExpiresOn.DateTime - $UTCDateTime).Minutes
        if ($TokenExpiresMinutes -le 10) {
            Write-Verbose -Message "Existing token found but is soon about to expire, refreshing token"
            Connect-MSIntuneGraph -TenantID $Global:AccessTokenTenantID -Refresh
        }

        # Convert and calculate required chunk elements for content upload
        $ChunkID = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($Chunk.ToString("0000")))
        $ChunkIDs += $ChunkID
        $Start = $Chunk * $ChunkSizeInBytes
        $Length = [System.Math]::Min($ChunkSizeInBytes, $FileSize - $Start)
        $Bytes = $BinaryReader.ReadBytes($Length)

        # Increment chunk to get the current chunk
        $CurrentChunk = $Chunk + 1

        Write-Progress -Activity "Uploading file to Azure Storage blob" -Status "Uploading chunk $($CurrentChunk) of $($ChunkCount)" -PercentComplete ($CurrentChunk / $ChunkCount * 100)
        Write-Verbose -Message "Uploading file to Azure Storage blob, processing chunk '$($CurrentChunk)' of '$($ChunkCount)'"
        $UploadResponse = Invoke-AzureStorageBlobUploadChunk -StorageUri $StorageUri -ChunkID $ChunkID -Bytes $Bytes
        
        if (($CurrentChunk -lt $ChunkCount) -and ($SASRenewalTimer.ElapsedMilliseconds -ge 450000)) {
            Write-Verbose -Message "SAS Uri renewal is required, attempting to renew"
            $RenewedSASUri = Invoke-AzureStorageBlobUploadRenew -Resource $Resource
            $SASRenewalTimer.Restart()
        }
    }

    # Stop timer
    $SASRenewalTimer.Stop()

    # Complete write status progress bar
    Write-Progress -Completed -Activity "Uploading File to Azure Storage blob"

    # Finalize the upload of the content file to Azure Storage blob
    Invoke-AzureStorageBlobUploadFinalize -StorageUri $StorageUri -ChunkID $ChunkIDs

    # Close and dispose binary reader object
    $BinaryReader.Close()
    $BinaryReader.Dispose()
}
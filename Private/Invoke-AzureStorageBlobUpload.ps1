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
        Updated:     2024-11-15

        Version history:
        1.0.0 - (2020-01-04) Function created
        1.0.1 - (2020-09-20) Fixed an issue where the System.IO.BinaryReader wouldn't open a file path containing whitespaces
        1.0.2 - (2021-03-15) Fixed an issue where SAS Uri renewal wasn't working correctly
        1.0.3 - (2022-09-03) Added access token refresh functionality when a token is about to expire, to prevent uploads from failing due to an expired access token
        1.0.5 - (2024-06-04) Added retry logic for chunk uploads and finalization steps to enhance reliability (thanks to @tjgruber)
        1.0.6 - (2024-11-15) Refactor date handling for token to fix locale-specific parsing issues (thanks to @tjgruber)
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

    # Allow time for SAS token propagation in Azure Storage backend
    Write-Verbose -Message "Waiting for Azure Storage SAS token propagation"
    Start-Sleep -Seconds 2

    # Start the timer for SAS URI renewal
    $SASRenewalTimer = [System.Diagnostics.Stopwatch]::StartNew()

    # Find the file size and open the file
    $FileSize = (Get-Item -Path $FilePath).Length
    $ChunkCount = [System.Math]::Ceiling($FileSize / $ChunkSizeInBytes)
    $BinaryReader = New-Object -TypeName System.IO.BinaryReader([System.IO.File]::Open($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite))
    $Position = $BinaryReader.BaseStream.Seek(0, [System.IO.SeekOrigin]::Begin)

    # Upload each chunk and check whether a SAS URI renewal is required after each chunk is uploaded and renew if needed
    $ChunkIDs = @()
    for ($Chunk = 0; $Chunk -lt $ChunkCount; $Chunk++) {
        Write-Verbose -Message "SAS Uri renewal timer has elapsed for: $($SASRenewalTimer.Elapsed.Minutes) minute $($SASRenewalTimer.Elapsed.Seconds) seconds"

        # Convert ExpiresOn to DateTimeOffset in UTC
        $ExpiresOnUTC = [DateTimeOffset]::Parse(
            $Global:AccessToken.ExpiresOn.ToString([System.Globalization.CultureInfo]::InvariantCulture),
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::AssumeUniversal
            ).ToUniversalTime()

        # Get the current UTC time as DateTimeOffset
        $UTCDateTime = [DateTimeOffset]::UtcNow

        # Calculate the TimeSpan between expiration and current time
        $TimeSpan = $ExpiresOnUTC - $UTCDateTime

        # Calculate the token expiration time in minutes
        $TokenExpireMinutes = [System.Math]::Round($TimeSpan.TotalMinutes)

        # Determine if refresh of access token is required when expiration count is less than or equal to minimum age
        if ($TokenExpireMinutes -le 10) {
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

        $UploadSuccess = $false
        $RetryCount = 8
        $RetryDelayRange = @{ Min = 7; Max = 30 }
        for ($i = 0; $i -lt $RetryCount; $i++) {
            try {
                $UploadResponse = Invoke-AzureStorageBlobUploadChunk -StorageUri $StorageUri -ChunkID $ChunkID -Bytes $Bytes
                $UploadSuccess = $true
                break
            } catch {
                $RetryDelay = Get-Random -Minimum $RetryDelayRange.Min -Maximum $RetryDelayRange.Max
                Write-Warning "Failed to upload chunk [$($CurrentChunk)] of [$($ChunkCount)]. Attempt [$($i + 1)] of [$RetryCount]. Retrying in [$RetryDelay] seconds. Error: $_"
                Start-Sleep -Seconds $RetryDelay
                Write-Warning "Retrying upload of chunk [$($CurrentChunk)] of [$($ChunkCount)]"
            }
        }

        if (-not $UploadSuccess) {
            Write-Error "Failed to upload chunk after [$RetryCount] attempts. Aborting upload."
            return
        }

        if (($CurrentChunk -lt $ChunkCount) -and ($SASRenewalTimer.ElapsedMilliseconds -ge 450000)) {
            Write-Verbose -Message "SAS Uri renewal is required, attempting to renew"
            try {
                $RenewedSASUri = Invoke-AzureStorageBlobUploadRenew -Resource $Resource
                if ($null -ne $RenewedSASUri) {
                    $StorageUri = $RenewedSASUri
                    $SASRenewalTimer.Restart()
                } else {
                    Write-Warning "SAS Uri renewal failed, continuing with existing Uri"
                }
            } catch {
                Write-Warning "SAS Uri renewal attempt failed with error: $_. Continuing with existing Uri."
            }
        }
    }

    # Stop timer
    $SASRenewalTimer.Stop()

    # Complete write status progress bar
    Write-Progress -Completed -Activity "Uploading File to Azure Storage blob"

    # Finalize the upload of the content file to Azure Storage blob
    $FinalizeSuccess = $false
    $RetryCount = 8
    $RetryDelayRange = @{ Min = 7; Max = 30 }
    for ($i = 0; $i -lt $RetryCount; $i++) {
        try {
            Invoke-AzureStorageBlobUploadFinalize -StorageUri $StorageUri -ChunkID $ChunkIDs
            $FinalizeSuccess = $true
            break
        } catch {
            $RetryDelay = Get-Random -Minimum $RetryDelayRange.Min -Maximum $RetryDelayRange.Max
            Write-Warning "Failed to finalize Azure Storage blob upload. Attempt [$($i + 1)] of [$RetryCount]. Retrying in [$RetryDelay] seconds. Error: $_"
            Start-Sleep -Seconds $RetryDelay
        }
    }

    if (-not $FinalizeSuccess) {
        Write-Error "Failed to finalize upload after [$RetryCount] attempts. Aborting upload."
        return
    }

    # Close and dispose binary reader object
    $BinaryReader.Close()
    $BinaryReader.Dispose()
}

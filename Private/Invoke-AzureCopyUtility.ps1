function Invoke-AzureCopyUtility {
    <#
    .SYNOPSIS
        Upload and commit .intunewin file into Azure Storage blob container.

    .DESCRIPTION
        Upload and commit .intunewin file into Azure Storage blob container.

    .PARAMETER StorageUri
        Specify the Storage Account Uri.

    .PARAMETER FilePath
        Specify the path to the file for upload.

    .PARAMETER Resource
        Specify the Storage Account files Uri for renewal if process takes a long time.


    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2022-10-02
        Updated:     2022-10-02

        Version history:
        1.0.0 - (2022-10-02) Function created
    #>    
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the Storage Account Uri.")]
        [ValidateNotNullOrEmpty()]
        [string]$StorageUri,

        [parameter(Mandatory = $true, HelpMessage = "Specify the path to the file for upload.")]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [parameter(Mandatory = $true, HelpMessage = "Specify the Storage Account files Uri for renewal if process takes a long time.")]
        [ValidateNotNullOrEmpty()]
        [string]$Resource
    )
    Process {
        # Download URL for AzCopy.exe
        $DownloadURL = "https://aka.ms/downloadazcopy-v10-windows"

        # Start the timer for SAS URI renewal
        $SASRenewalTimer = [System.Diagnostics.Stopwatch]::StartNew()

        # Construct expected path to AzCopy utility
        $AzCopyPath = Resolve-Path -Path (Join-Path -Path $env:TEMP -ChildPath "AzCopy\azcopy_windows_amd64*") -ErrorAction "SilentlyContinue" | Select-Object -ExpandProperty "Path"

        if ($AzCopyPath -eq $null) {
            try {
                # Download AzCopy.exe if not present in context temporary folder
                Write-Verbose -Message "Unable to detect AzCopy.exe in specified location, attempting to download to: $($env:TEMP)"
                Start-DownloadFile -URL $DownloadURL -Path $env:TEMP -Name "AzCopy.zip" -ErrorAction "Stop"

                try {
                    # Expand downloaded zip archive
                    $AzCopyExtractedPath = (Join-Path -Path $env:TEMP -ChildPath "AzCopy")
                    Expand-Archive -Path (Join-Path -Path $env:TEMP -ChildPath "AzCopy.zip") -DestinationPath $AzCopyExtractedPath -ErrorAction "Stop"
                }
                catch [System.Exception] {
                    throw "$($MyInvocation.MyCommand): Failed to extract AzCopy.exe with error message: $($_.Exception.Message)"
                }
            }
            catch [System.Exception] {
                throw "$($MyInvocation.MyCommand): Failed to download AzCopy.exe from '$($DownloadURL)' with error message: $($_.Exception.Message)"
            }
        }

        # Attempt to resolve path to AzCopy.exe in extracted content
        $AzCopyPath = Join-Path -Path (Resolve-Path -Path (Join-Path -Path $env:TEMP -ChildPath "AzCopy\azcopy_windows_amd64*") | Select-Object -ExpandProperty "Path") -ChildPath "AzCopy.exe"
        if ($AzCopyPath -ne $null) {
            try {
                $TransferOperation = Start-Process -FilePath $AzCopyPath -ArgumentList "cp `"$($FilePath)`" `"$($StorageUri)`" --output-type `"json`"" -PassThru -NoNewWindow -ErrorAction "Stop"
                do {
                    # Wait for 10 seconds until next loop conditional statement check occurs
                    Start-Sleep -Seconds 10

                    # Ensure the SAS Uri is renewed
                    if ($SASRenewalTimer.ElapsedMilliseconds -ge 450000) {
                        Write-Verbose -Message "SAS Uri renewal is required, attempting to renew"
                        $RenewedSASUri = Invoke-AzureStorageBlobUploadRenew -Resource $Resource
                        $SASRenewalTimer.Restart()
                    }
                }
                until ($TransferOperation.HasExited -eq $true)
            }
            catch [System.Exception] {
                throw "$($MyInvocation.MyCommand): AzCopy.exe file transfer failed. Error message: $($_.Exception.Message)"
            }
            finally {
                Write-Verbose -Message "AzCopy.exe file transfer completed"
            }
        }
        else {
            throw "$($MyInvocation.MyCommand): AzCopy.exe could not be found, this transfer method cannot be used"
        }
    }
    End {
        # Stop timer
        $SASRenewalTimer.Stop()
    }
}
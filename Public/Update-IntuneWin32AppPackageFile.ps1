function Update-IntuneWin32AppPackageFile {
    <#
    .SYNOPSIS
        Update the package content file for an existing Win32 app.

    .DESCRIPTION
        Update the package content file for an existing Win32 app.

    .PARAMETER ID
        Specify the ID for a Win32 application.

    .PARAMETER FilePath
        Specify a local path to where the win32 app .intunewin file is located.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-10-01
        Updated:     2023-09-04

        Version history:
        1.0.0 - (2020-10-01) Function created
        1.0.1 - (2021-04-01) Updated token expired message to a warning instead of verbose output
        1.0.2 - (2021-08-31) Updated to use new authentication header
        1.0.3 - (2021-08-31) Fixed an issue where the PATCH operation would remove the largeIcon property value of the Win32 app
        1.0.4 - (2023-01-20) Updated regex pattern for parameter FilePath
        1.0.5 - (2023-09-04) Updated with Test-AccessToken function
        1.0.6 - (2024-12-19) Added logic to make Expand folder unique to avoid file access conflicts. (tjgruber)
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the ID for a Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$ID,

        [parameter(Mandatory = $true, HelpMessage = "Specify a local path to where the win32 app .intunewin file is located.")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            # Check if file name contains any invalid characters
            if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
                throw "File name '$(Split-Path -Path $_ -Leaf)' contains invalid characters"
            }
            else {
                # Check if full path exist
                if (Test-Path -Path $_) {
                    # Check if file extension is intunewin
                    if ([System.IO.Path]::GetExtension((Split-Path -Path $_ -Leaf)) -like ".intunewin") {
                        return $true
                    }
                    else {
                        throw "Given file name '$(Split-Path -Path $_ -Leaf)' contains an unsupported file extension. Supported extension is '.intunewin'"
                    }
                }
                else {
                    throw "File or folder does not exist"
                }
            }
        })]
        [string]$FilePath
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
        # Attempt to gather all possible meta data from specified .intunewin file
        Write-Verbose -Message "Attempting to gather additional meta data from .intunewin file: $($FilePath)"
        $IntuneWinXMLMetaData = Get-IntuneWin32AppMetaData -FilePath $FilePath -ErrorAction Stop
        if ($IntuneWinXMLMetaData -ne $null) {
            Write-Verbose -Message "Successfully gathered additional meta data from .intunewin file"

            # Retrieve Win32 app by ID from parameter input
            Write-Verbose -Message "Querying for Win32 app using ID: $($ID)"
            $Win32App = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($ID)" -Method "GET"
            if ($Win32App -ne $null) {
                # Create Content Version for the Win32 app
                Write-Verbose -Message "Attempting to create contentVersions resource for the Win32 app"
                $Win32AppContentVersionRequest = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32App.id)/microsoft.graph.win32LobApp/contentVersions" -Method "POST" -Body "{}"
                if ([string]::IsNullOrEmpty($Win32AppContentVersionRequest.id)) {
                    Write-Warning -Message "Failed to create contentVersions resource for Win32 app"; break
                }
                else {
                    Write-Verbose -Message "Successfully created contentVersions resource with ID: $($Win32AppContentVersionRequest.id)"

                    # Extract compressed .intunewin file to subfolder
                    $SubFolderName = "Expand_" + [System.Guid]::NewGuid().ToString("N").Substring(0, 12)
                    $IntuneWinFilePath = Expand-IntuneWin32AppCompressedFile -FilePath $FilePath -FileName $IntuneWinXMLMetaData.ApplicationInfo.FileName -FolderName $SubFolderName
                    if ($IntuneWinFilePath -ne $null) {
                        # Create a new file entry in Intune for the upload of the .intunewin file
                        Write-Verbose -Message "Constructing Win32 app content file body for uploading of .intunewin file"
                        $Win32AppFileBody = [ordered]@{
                            "@odata.type" = "#microsoft.graph.mobileAppContentFile"
                            "name" = $IntuneWinXMLMetaData.ApplicationInfo.FileName
                            "size" = [int64]$IntuneWinXMLMetaData.ApplicationInfo.UnencryptedContentSize
                            "sizeEncrypted" = (Get-Item -Path $IntuneWinFilePath).Length
                            "manifest" = $null
                            "isDependency" = $false
                        }

                        # Create the contentVersions files resource
                        $Win32AppFileContentRequest = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32App.id)/microsoft.graph.win32LobApp/contentVersions/$($Win32AppContentVersionRequest.id)/files" -Method "POST" -Body ($Win32AppFileBody | ConvertTo-Json)
                        if ([string]::IsNullOrEmpty($Win32AppFileContentRequest.id)) {
                            Write-Warning -Message "Failed to create Azure Storage blob for contentVersions/files resource for Win32 app"
                        }
                        else {
                            # Wait for the Win32 app file content URI to be created
                            Write-Verbose -Message "Waiting for Intune service to process contentVersions/files request"
                            $FilesUri = "mobileApps/$($Win32App.id)/microsoft.graph.win32LobApp/contentVersions/$($Win32AppContentVersionRequest.id)/files/$($Win32AppFileContentRequest.id)"
                            $ContentVersionsFiles = Wait-IntuneWin32AppFileProcessing -Stage "AzureStorageUriRequest" -Resource $FilesUri
                            
                            # Upload .intunewin file to Azure Storage blob
                            Invoke-AzureStorageBlobUpload -StorageUri $ContentVersionsFiles.azureStorageUri -FilePath $IntuneWinFilePath -Resource $FilesUri

                            # Retrieve encryption meta data from .intunewin file
                            $IntuneWinEncryptionInfo = [ordered]@{
                                "encryptionKey" = $IntuneWinXMLMetaData.ApplicationInfo.EncryptionInfo.EncryptionKey
                                "macKey" = $IntuneWinXMLMetaData.ApplicationInfo.EncryptionInfo.macKey
                                "initializationVector" = $IntuneWinXMLMetaData.ApplicationInfo.EncryptionInfo.initializationVector
                                "mac" = $IntuneWinXMLMetaData.ApplicationInfo.EncryptionInfo.mac
                                "profileIdentifier" = "ProfileVersion1"
                                "fileDigest" = $IntuneWinXMLMetaData.ApplicationInfo.EncryptionInfo.fileDigest
                                "fileDigestAlgorithm" = $IntuneWinXMLMetaData.ApplicationInfo.EncryptionInfo.fileDigestAlgorithm
                            }
                            $IntuneWinFileEncryptionInfo = @{
                                "fileEncryptionInfo" = $IntuneWinEncryptionInfo
                            }

                            # Create file commit request
                            $CommitResource = "mobileApps/$($Win32App.id)/microsoft.graph.win32LobApp/contentVersions/$($Win32AppContentVersionRequest.id)/files/$($Win32AppFileContentRequest.id)/commit"
                            $Win32AppFileCommitRequest = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource $CommitResource -Method "POST" -Body ($IntuneWinFileEncryptionInfo | ConvertTo-Json)

                            # Wait for Intune service to process the commit file request
                            Write-Verbose -Message "Waiting for Intune service to process the commit file request"
                            $CommitFileRequest = Wait-IntuneWin32AppFileProcessing -Stage "CommitFile" -Resource $FilesUri
                            
                            # Update committedContentVersion property for Win32 app
                            Write-Verbose -Message "Updating committedContentVersion property with ID '$($Win32AppContentVersionRequest.id)' for Win32 app with ID: $($Win32App.id)"
                            $Win32AppFileCommitBody = [ordered]@{
                                "@odata.type" = "#microsoft.graph.win32LobApp"
                                "committedContentVersion" = $Win32AppContentVersionRequest.id
                                "largeIcon" = $Win32App.largeIcon
                            }
                            $Win32AppFileCommitBodyRequest = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32App.id)" -Method "PATCH" -Body ($Win32AppFileCommitBody | ConvertTo-Json)

                            # Handle return output
                            Write-Verbose -Message "Successfully updated Win32 app and committed file content to Azure Storage blob"
                            $Win32AppRequest = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32App.id)" -Method "GET"
                            Write-Output -InputObject $Win32AppRequest
                        }

                        # Cleanup extracted .intunewin file in Extract folder
                        Remove-Item -Path (Split-Path -Path $IntuneWinFilePath -Parent) -Recurse -Force -Confirm:$false | Out-Null
                    }
                }
            }
            else {
                Write-Warning -Message "Query for Win32 app using '$($ID)' returned empty response"
            }
        }
        else {
            Write-Warning -Message "Unable to retrieve required meta data from .intunewin file: $($FilePath)"
        }
    }
}
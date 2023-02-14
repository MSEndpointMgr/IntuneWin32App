function Add-IntuneWin32App {
    <#
    .SYNOPSIS
        Create a new Win32 application in Microsoft Intune.

    .DESCRIPTION
        Create a new Win32 application in Microsoft Intune.

    .PARAMETER FilePath
        Specify a local path to where the win32 app .intunewin file is located.

    .PARAMETER DisplayName
        Specify a display name for the Win32 application.
    
    .PARAMETER Description
        Specify a description for the Win32 application.
    
    .PARAMETER Publisher
        Specify a publisher name for the Win32 application.

    .PARAMETER AppVersion
        Specify the app version for the Win32 application.
    
    .PARAMETER Developer
        Specify the developer name for the Win32 application.

    .PARAMETER Owner
        Specify the owner property for the Win32 application.

    .PARAMETER Notes
        Specify the notes property for the Win32 application.

    .PARAMETER InformationURL
        Specify the information URL for the Win32 application.
    
    .PARAMETER PrivacyURL
        Specify the privacy URL for the Win32 application.
    
    .PARAMETER CompanyPortalFeaturedApp
        Specify whether to have the Win32 application featured in Company Portal or not.

    .PARAMETER InstallCommandLine
        Specify the install command line for the Win32 application.
    
    .PARAMETER UninstallCommandLine
        Specify the uninstall command line for the Win32 application.

    .PARAMETER InstallExperience
        Specify the install experience for the Win32 application. Supported values are: system or user.
    
    .PARAMETER RestartBehavior
        Specify the restart behavior for the Win32 application. Supported values are: allow, basedOnReturnCode, suppress or force.
    
    .PARAMETER DetectionRule
        Provide an array of a single or multiple OrderedDictionary objects as detection rules that will be used for the Win32 application.

    .PARAMETER RequirementRule
        Provide an OrderedDictionary object as requirement rule that will be used for the Win32 application.

    .PARAMETER AdditionalRequirementRule
        Provide an array of OrderedDictionary objects as additional requirement rule, e.g. for file, registry or script rules, that will be used for the Win32 application.

    .PARAMETER ReturnCode
        Provide an array of a single or multiple hash-tables for the Win32 application with return code information.

    .PARAMETER Icon
        Provide a Base64 encoded string of the PNG/JPG/JPEG file.

    .PARAMETER UseAzCopy
        Specify the UseAzCopy parameter switch when adding an application with source files larger than 500MB.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-01-04
        Updated:     2022-10-02

        Version history:
        1.0.0 - (2020-01-04) Function created
        1.0.1 - (2020-01-27) Added support for RequirementRule parameter input
        1.0.2 - (2020-09-20) Added support for Owner, Notes, InformationURL, PrivacyURL and CompanyPortalFeaturedApp parameter inputs
        1.0.3 - (2021-04-01) Removed unused comments
        1.0.4 - (2021-04-01) Updated token expired message to a warning instead of verbose output
        1.0.5 - (2021-08-31) Updated to use new authentication header
        1.0.6 - (2021-08-31) Added AppVersion optional parameter
        1.0.7 - (2022-09-02) Removed break command that would prevent the Win32 app body JSON output from being display in case an error occured
        1.0.8 - (2022-10-02) Added UseAzCopy parameter switch to override the native transfer method. Specify the UseAzCopy parameter switch when uploading large applications.
                             Added fallback removal code for the cleanup operation at the end of this function, since OneDrive's Files On Demand feature sometimes blocks the 
                             expanded .intunewin file cleanup process.
    #>
    [CmdletBinding(SupportsShouldProcess=$true, DefaultParameterSetName = "MSI")]
    param(
        [parameter(Mandatory = $true, ParameterSetName = "MSI", HelpMessage = "Specify a local path to where the win32 app .intunewin file is located.")]
        [parameter(Mandatory = $true, ParameterSetName = "EXE")]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^[A-Za-z]{1}:\\\w+")]
        [ValidateScript({
            # Check if path contains any invalid characters
            if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
                Write-Warning -Message "$(Split-Path -Path $_ -Leaf) contains invalid characters"; break
            }
            else {
            # Check if file extension is intunewin
                if ([System.IO.Path]::GetExtension((Split-Path -Path $_ -Leaf)) -like ".intunewin") {
                    return $true
                }
                else {
                    Write-Warning -Message "$(Split-Path -Path $_ -Leaf) contains unsupported file extension. Supported extension is '.intunewin'"; break
                }
            }
        })]
        [string]$FilePath,

        [parameter(Mandatory = $true, ParameterSetName = "MSI", HelpMessage = "Specify a display name for the Win32 application.")]
        [parameter(Mandatory = $true, ParameterSetName = "EXE")]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [parameter(Mandatory = $true, ParameterSetName = "MSI", HelpMessage = "Specify a description for the Win32 application.")]
        [parameter(Mandatory = $true, ParameterSetName = "EXE")]
        [ValidateNotNullOrEmpty()]
        [string]$Description,

        [parameter(Mandatory = $true, ParameterSetName = "MSI", HelpMessage = "Specify a publisher name for the Win32 application.")]
        [parameter(Mandatory = $true, ParameterSetName = "EXE")]
        [ValidateNotNullOrEmpty()]
        [string]$Publisher,

        [parameter(Mandatory = $false, ParameterSetName = "MSI", HelpMessage = "Specify the app version for the Win32 application.")]
        [parameter(Mandatory = $false, ParameterSetName = "EXE")]
        [string]$AppVersion = [string]::Empty,

        [parameter(Mandatory = $false, ParameterSetName = "MSI", HelpMessage = "Specify the developer name for the Win32 application.")]
        [parameter(Mandatory = $false, ParameterSetName = "EXE")]
        [string]$Developer = [string]::Empty,

        [parameter(Mandatory = $false, ParameterSetName = "MSI", HelpMessage = "Specify the owner property for the Win32 application.")]
        [parameter(Mandatory = $false, ParameterSetName = "EXE")]
        [string]$Owner = [string]::Empty,

        [parameter(Mandatory = $false, ParameterSetName = "MSI", HelpMessage = "Specify the notes property for the Win32 application.")]
        [parameter(Mandatory = $false, ParameterSetName = "EXE")]
        [string]$Notes = [string]::Empty,

        [parameter(Mandatory = $false, ParameterSetName = "MSI", HelpMessage = "Specify the information URL for the Win32 application.")]
        [parameter(Mandatory = $false, ParameterSetName = "EXE")]
        [ValidatePattern("(http[s]?|[s]?ftp[s]?)(:\/\/)([^\s,]+)")]
        [string]$InformationURL = [string]::Empty,

        [parameter(Mandatory = $false, ParameterSetName = "MSI", HelpMessage = "Specify the privacy URL for the Win32 application.")]
        [parameter(Mandatory = $false, ParameterSetName = "EXE")]
        [ValidatePattern("(http[s]?|[s]?ftp[s]?)(:\/\/)([^\s,]+)")]
        [string]$PrivacyURL = [string]::Empty,

        [parameter(Mandatory = $false, ParameterSetName = "MSI", HelpMessage = "Specify whether to have the Win32 application featured in Company Portal or not.")]
        [parameter(Mandatory = $false, ParameterSetName = "EXE")]
        [bool]$CompanyPortalFeaturedApp = $false,

        [parameter(Mandatory = $true, ParameterSetName = "EXE", HelpMessage = "Specify the install command line for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$InstallCommandLine,

        [parameter(Mandatory = $true, ParameterSetName = "EXE", HelpMessage = "Specify the uninstall command line for the Win32 application.")]
        [ValidateNotNullOrEmpty()]
        [string]$UninstallCommandLine,

        [parameter(Mandatory = $true, ParameterSetName = "MSI", HelpMessage = "Specify the install experience for the Win32 application. Supported values are: system or user.")]
        [parameter(Mandatory = $true, ParameterSetName = "EXE")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("system", "user")]
        [string]$InstallExperience,

        [parameter(Mandatory = $true, ParameterSetName = "MSI", HelpMessage = "Specify the restart behavior for the Win32 application. Supported values are: allow, basedOnReturnCode, suppress or force.")]
        [parameter(Mandatory = $true, ParameterSetName = "EXE")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("allow", "basedOnReturnCode", "suppress", "force")]
        [string]$RestartBehavior,

        [parameter(Mandatory = $true, ParameterSetName = "MSI", HelpMessage = "Provide an array of a single or multiple OrderedDictionary objects as detection rules that will be used for the Win32 application.")]
        [parameter(Mandatory = $true, ParameterSetName = "EXE")]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.OrderedDictionary[]]$DetectionRule,

        [parameter(Mandatory = $false, ParameterSetName = "MSI", HelpMessage = "Provide an OrderedDictionary object as requirement rule that will be used for the Win32 application.")]
        [parameter(Mandatory = $false, ParameterSetName = "EXE")]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.OrderedDictionary]$RequirementRule,

        [parameter(Mandatory = $false, ParameterSetName = "MSI", HelpMessage = "Provide an array of OrderedDictionary objects as additional requirement rule, e.g. for file, registry or script rules, that will be used for the Win32 application.")]
        [parameter(Mandatory = $false, ParameterSetName = "EXE")]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.OrderedDictionary[]]$AdditionalRequirementRule,

        [parameter(Mandatory = $false, ParameterSetName = "MSI", HelpMessage = "Provide an array of a single or multiple hash-tables for the Win32 application with return code information.")]
        [parameter(Mandatory = $false, ParameterSetName = "EXE")]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable[]]$ReturnCode,

        [parameter(Mandatory = $false, ParameterSetName = "MSI", HelpMessage = "Provide a Base64 encoded string of the PNG/JPG/JPEG file.")]
        [parameter(Mandatory = $false, ParameterSetName = "EXE")]
        [ValidateNotNullOrEmpty()]
        [string]$Icon,

        [parameter(Mandatory = $false, ParameterSetName = "MSI", HelpMessage = "Specify the UseAzCopy parameter switch when adding an application with source files larger than 500MB.")]
        [parameter(Mandatory = $false, ParameterSetName = "EXE")]
        [ValidateNotNullOrEmpty()]
        [switch]$UseAzCopy
    )
    Begin {
        # Ensure required authentication header variable exists
        if ($Global:AuthenticationHeader -eq $null) {
            Write-Warning -Message "Authentication token was not found, use Connect-MSIntuneGraph before using this function"; break
        }
        else {
            $TokenLifeTime = ($Global:AuthenticationHeader.ExpiresOn - (Get-Date).ToUniversalTime()).Minutes
            if ($TokenLifeTime -le 0) {
                Write-Warning -Message "Existing token found but has expired, use Connect-MSIntuneGraph to request a new authentication token"; break
            }
            else {
                Write-Verbose -Message "Current authentication token expires in (minutes): $($TokenLifeTime)"
            }
        }

        # Set script variable for error action preference
        $ErrorActionPreference = "Stop"
    }
    Process {
        try {
            # Attempt to gather all possible meta data from specified .intunewin file
            Write-Verbose -Message "Attempting to gather additional meta data from .intunewin file: $($FilePath)"
            $IntuneWinXMLMetaData = Get-IntuneWin32AppMetaData -FilePath $FilePath -ErrorAction Stop

            if ($IntuneWinXMLMetaData -ne $null) {
                Write-Verbose -Message "Successfully gathered additional meta data from .intunewin file"

                # Generate Win32 application body data table with different parameters based upon parameter set name
                Write-Verbose -Message "Start constructing basic layout of Win32 app body"
                switch ($PSCmdlet.ParameterSetName) {
                    "MSI" {
                        # Determine the execution context of the MSI installer and define the installation purpose
                        $MSIExecutionContext = $IntuneWinXMLMetaData.ApplicationInfo.MsiInfo.MsiExecutionContext
                        $MSIInstallPurpose = "DualPurpose"
                        switch ($MSIExecutionContext) {
                            "System" {
                                $MSIInstallPurpose = "PerMachine"
                            }
                            "User" {
                                $MSIInstallPurpose = "PerUser"
                            }
                        }

                        # Handle special meta data variable values
                        $MSIRequiresReboot = $IntuneWinXMLMetaData.ApplicationInfo.MsiInfo.MsiRequiresReboot
                        switch ($MSIRequiresReboot) {
                            "true" {
                                $MSIRequiresReboot = $true
                            }
                            "false" {
                                $MSIRequiresReboot = $false
                            }
                        }

                        # Handle special parameter inputs
                        if (-not($PSBoundParameters["DisplayName"])) {
                            $DisplayName = $IntuneWinXMLMetaData.ApplicationInfo.Name
                        }
                        if (-not($PSBoundParameters["Description"])) {
                            $Description = $IntuneWinXMLMetaData.ApplicationInfo.Name
                        }
                        if (-not($PSBoundParameters["Publisher"])) {
                            $Publisher = $IntuneWinXMLMetaData.ApplicationInfo.MsiInfo.MsiPublisher
                        }
                        if (-not($PSBoundParameters["Developer"])) {
                            $Developer = [string]::Empty
                        }
                        
                        # Generate Win32 application body
                        $AppBodySplat = @{
                            "MSI" = $true
                            "DisplayName" = $DisplayName
                            "Description" = $Description
                            "Publisher" = $Publisher
                            "AppVersion" = $AppVersion
                            "Developer" = $Developer
                            "Owner" = $Owner
                            "Notes" = $Notes
                            "InformationURL" = $InformationURL
                            "PrivacyURL" = $PrivacyURL
                            "CompanyPortalFeaturedApp" = $CompanyPortalFeaturedApp
                            "FileName" = $IntuneWinXMLMetaData.ApplicationInfo.FileName
                            "SetupFileName" = $IntuneWinXMLMetaData.ApplicationInfo.SetupFile
                            "InstallExperience" = $InstallExperience
                            "RestartBehavior" = $RestartBehavior
                            "MSIInstallPurpose" = $MSIInstallPurpose
                            "MSIProductCode" = $IntuneWinXMLMetaData.ApplicationInfo.MsiInfo.MsiProductCode
                            "MSIProductName" = $DisplayName
                            "MSIProductVersion" = $IntuneWinXMLMetaData.ApplicationInfo.MsiInfo.MsiProductVersion
                            "MSIRequiresReboot" = $MSIRequiresReboot
                            "MSIUpgradeCode" = $IntuneWinXMLMetaData.ApplicationInfo.MsiInfo.MsiUpgradeCode
                        }
                        if ($PSBoundParameters["Icon"]) {
                            $AppBodySplat.Add("Icon", $Icon)
                        }
                        if ($PSBoundParameters["RequirementRule"]) {
                            $AppBodySplat.Add("RequirementRule", $RequirementRule)
                        }

                        $Win32AppBody = New-IntuneWin32AppBody @AppBodySplat
                        Write-Verbose -Message "Constructed the basic layout for 'MSI' Win32 app body type"
                    }
                    "EXE" {
                        # Generate Win32 application body
                        $AppBodySplat = @{
                            "EXE" = $true
                            "DisplayName" = $DisplayName
                            "Description" = $Description
                            "Publisher" = $Publisher
                            "AppVersion" = $AppVersion
                            "Developer" = $Developer
                            "Owner" = $Owner
                            "Notes" = $Notes
                            "InformationURL" = $InformationURL
                            "PrivacyURL" = $PrivacyURL
                            "CompanyPortalFeaturedApp" = $CompanyPortalFeaturedApp
                            "FileName" = $IntuneWinXMLMetaData.ApplicationInfo.FileName
                            "SetupFileName" = $IntuneWinXMLMetaData.ApplicationInfo.SetupFile
                            "InstallExperience" = $InstallExperience
                            "RestartBehavior" = $RestartBehavior
                            "InstallCommandLine" = $InstallCommandLine
                            "UninstallCommandLine" = $UninstallCommandLine
                        }
                        if ($PSBoundParameters["Icon"]) {
                            $AppBodySplat.Add("Icon", $Icon)
                        }
                        if ($PSBoundParameters["RequirementRule"]) {
                            $AppBodySplat.Add("RequirementRule", $RequirementRule)
                        }

                        $Win32AppBody = New-IntuneWin32AppBody @AppBodySplat
                        Write-Verbose -Message "Constructed the basic layout for 'EXE' Win32 app body type"
                    }
                }

                # Validate that correct detection rules have been passed on command line, only 1 PowerShell script based detection rule is allowed
                if (($DetectionRule.'@odata.type' -contains "#microsoft.graph.win32LobAppPowerShellScriptDetection") -and (@($DetectionRules).'@odata.type'.Count -gt 1)) {
                    Write-Warning -Message "Multiple PowerShell Script detection rules were detected, this is not a supported configuration"; break
                }
               
                # Add detection rules to Win32 app body object
                Write-Verbose -Message "Detection rule objects passed validation checks, attempting to add to existing Win32 app body"
                $Win32AppBody.Add("detectionRules", $DetectionRule)

                # Retrieve the default return codes for a Win32 app
                Write-Verbose -Message "Retrieving default set of return codes for Win32 app body construction"
                $DefaultReturnCodes = Get-IntuneWin32AppDefaultReturnCode

                # Add custom return codes from parameter input to default set of objects
                if ($PSBoundParameters["ReturnCode"]) {
                    Write-Verbose -Message "Additional return codes where passed as command line input, adding to array of default return codes"
                    foreach ($ReturnCodeItem in $ReturnCode) {
                        $DefaultReturnCodes += $ReturnCodeItem
                    }
                }

                # Add return codes to Win32 app body object
                Write-Verbose -Message "Adding array of return codes to Win32 app body construction"
                $Win32AppBody.Add("returnCodes", $DefaultReturnCodes)

                # Add additional requirement rules to Win32 app body object
                if ($PSBoundParameters["AdditionalRequirementRule"]) {
                    $Win32AppBody.Add("requirementRules", $AdditionalRequirementRule)
                }

                # Create the Win32 app
                Write-Verbose -Message "Attempting to create Win32 app using constructed body converted to JSON content"
                $Win32MobileAppRequest = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps" -Method "POST" -Body ($Win32AppBody | ConvertTo-Json)
                if ($Win32MobileAppRequest.'@odata.type' -notlike "#microsoft.graph.win32LobApp") {
                    Write-Warning -Message "Failed to create Win32 app using constructed body. Passing converted body as JSON to output."
                    Write-Warning -Message ($Win32AppBody | ConvertTo-Json); break
                }
                else {
                    Write-Verbose -Message "Successfully created Win32 app with ID: $($Win32MobileAppRequest.id)"

                    # Create Content Version for the Win32 app
                    Write-Verbose -Message "Attempting to create contentVersions resource for the Win32 app"
                    $Win32MobileAppContentVersionRequest = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32MobileAppRequest.id)/microsoft.graph.win32LobApp/contentVersions" -Method "POST" -Body "{}"
                    if ([string]::IsNullOrEmpty($Win32MobileAppContentVersionRequest.id)) {
                        Write-Warning -Message "Failed to create contentVersions resource for Win32 app"
                    }
                    else {
                        Write-Verbose -Message "Successfully created contentVersions resource with ID: $($Win32MobileAppContentVersionRequest.id)"

                        # Extract compressed .intunewin file to subfolder
                        $IntuneWinFilePath = Expand-IntuneWin32AppCompressedFile -FilePath $FilePath -FileName $IntuneWinXMLMetaData.ApplicationInfo.FileName -FolderName "Expand"
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
                            $Win32MobileAppFileContentRequest = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32MobileAppRequest.id)/microsoft.graph.win32LobApp/contentVersions/$($Win32MobileAppContentVersionRequest.id)/files" -Method "POST" -Body ($Win32AppFileBody | ConvertTo-Json)
                            if ([string]::IsNullOrEmpty($Win32MobileAppFileContentRequest.id)) {
                                Write-Warning -Message "Failed to create Azure Storage blob for contentVersions/files resource for Win32 app"
                            }
                            else {
                                # Wait for the Win32 app file content URI to be created
                                Write-Verbose -Message "Waiting for Intune service to process contentVersions/files request"
                                $FilesUri = "mobileApps/$($Win32MobileAppRequest.id)/microsoft.graph.win32LobApp/contentVersions/$($Win32MobileAppContentVersionRequest.id)/files/$($Win32MobileAppFileContentRequest.id)"
                                $ContentVersionsFiles = Wait-IntuneWin32AppFileProcessing -Stage "AzureStorageUriRequest" -Resource $FilesUri

                                # Upload .intunewin file to Azure Storage blob
                                if ($PSBoundParameters["UseAzCopy"]) {
                                    try {
                                        Write-Verbose -Message "Using AzCopy.exe method for file transfer"
                                        Invoke-AzureCopyUtility -StorageUri $ContentVersionsFiles.azureStorageUri -FilePath $IntuneWinFilePath -Resource $FilesUri -ErrorAction "Stop"
                                    }
                                    catch [System.Exception] {
                                        Write-Verbose -Message "AzCopy.exe transfer method failed with exception message: $($_.Exception.Message)"
                                        Write-Verbose -Message "Falling back to native method"
                                        Invoke-AzureStorageBlobUpload -StorageUri $ContentVersionsFiles.azureStorageUri -FilePath $IntuneWinFilePath -Resource $FilesUri
                                    }
                                }
                                else {
                                    Write-Verbose -Message "Using native method for file transfer"
                                    Invoke-AzureStorageBlobUpload -StorageUri $ContentVersionsFiles.azureStorageUri -FilePath $IntuneWinFilePath -Resource $FilesUri
                                }

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
                                $CommitResource = "mobileApps/$($Win32MobileAppRequest.id)/microsoft.graph.win32LobApp/contentVersions/$($Win32MobileAppContentVersionRequest.id)/files/$($Win32MobileAppFileContentRequest.id)/commit"
                                $Win32AppFileCommitRequest = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource $CommitResource -Method "POST" -Body ($IntuneWinFileEncryptionInfo | ConvertTo-Json)

                                # Wait for Intune service to process the commit file request
                                Write-Verbose -Message "Waiting for Intune service to process the commit file request"
                                $CommitFileRequest = Wait-IntuneWin32AppFileProcessing -Stage "CommitFile" -Resource $FilesUri
                                
                                # Update committedContentVersion property for Win32 app
                                Write-Verbose -Message "Updating committedContentVersion property with ID '$($Win32MobileAppContentVersionRequest.id)' for Win32 app with ID: $($Win32MobileAppRequest.id)"
                                $Win32AppFileCommitBody = [ordered]@{
                                    "@odata.type" = "#microsoft.graph.win32LobApp"
                                    "committedContentVersion" = $Win32MobileAppContentVersionRequest.id
                                }
                                $Win32AppFileCommitBodyRequest = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32MobileAppRequest.id)" -Method "PATCH" -Body ($Win32AppFileCommitBody | ConvertTo-Json)

                                # Handle return output
                                Write-Verbose -Message "Successfully created Win32 app and committed file content to Azure Storage blob"
                                $Win32MobileAppRequest = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32MobileAppRequest.id)" -Method "GET"
                                Write-Output -InputObject $Win32MobileAppRequest
                            }

                            try {
                                # Cleanup extracted .intunewin file in Extract folder
                                Remove-Item -Path (Split-Path -Path $IntuneWinFilePath -Parent) -Recurse -Force -Confirm:$false | Out-Null
                            }
                            catch [System.Exception] {
                                # Fallback method if OneDrive's Files On Demand feature is blocking access
                                $FileItems = Get-ChildItem -LiteralPath $IntuneWinFilePath -Recurse
                                foreach ($FileItem in $FileItems) {
                                    $FileItem.Delete()
                                }
                                $ParentItem = Get-Item -LiteralPath $IntuneWinFilePath
                                $ParentItem.Delete($true)
                            }
                        }
                    }
                }
            }
        }
        catch [System.Exception] {
            Write-Warning -Message "An error occurred while creating the Win32 application. Error message: $($_.Exception.Message)"
        }
    }
}
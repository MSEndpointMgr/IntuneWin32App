function New-IntuneWin32AppPackage {
    <#
    .SYNOPSIS
        Package an application as a Win32 application container (.intunewin) for usage with Microsoft Intune.

    .DESCRIPTION
        Package an application as a Win32 application container (.intunewin) for usage with Microsoft Intune.

    .PARAMETER SourceFolder
        Specify the full path of the source folder where the setup file and all of it's potential dependency files reside.

    .PARAMETER SetupFile
        Specify the complete setup file name including it's file extension, e.g. Setup.exe or Installer.msi.

    .PARAMETER OutputFolder
        Specify the full path of the output folder where the packaged .intunewin file will be exported to.

    .PARAMETER Force
        Specify to overwrite existing packaged .intunewin file if already present in output folder.

    .PARAMETER IntuneWinAppUtilPath
        Specify the full path to the IntuneWinAppUtil.exe file.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-01-04
        Updated:     2023-01-23

        Version history:
        1.0.0 - (2020-01-04) Function created
        1.0.1 - (2020-05-03) Added trimming of trailing backslashes passed to input paths to prevent unwanted errors
        1.0.2 - (2023-01-23) Added Force parameter, function now also checks if an existing .intunewin file is present in the output folder and prompts accordingly
    #>    
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the full path of the source folder where the setup file and all of it's potential dependency files reside.")]
        [ValidateNotNullOrEmpty()]
        [string]$SourceFolder,

        [parameter(Mandatory = $true, HelpMessage = "Specify the complete setup file name including it's file extension, e.g. Setup.exe or Installer.msi.")]
        [ValidateNotNullOrEmpty()]
        [string]$SetupFile,

        [parameter(Mandatory = $true, HelpMessage = "Specify the full path of the output folder where the packaged .intunewin file will be exported to.")]
        [ValidateNotNullOrEmpty()]
        [string]$OutputFolder,

        [parameter(Mandatory = $false, HelpMessage = "Specify to overwrite existing packaged .intunewin file if already present in output folder.")]
        [ValidateNotNullOrEmpty()]
        [switch]$Force,

        [parameter(Mandatory = $false, HelpMessage = "Specify the full path to the IntuneWinAppUtil.exe file.")]
        [ValidateNotNullOrEmpty()]
        [string]$IntuneWinAppUtilPath = (Join-Path -Path $env:TEMP -ChildPath "IntuneWinAppUtil.exe")
    )
    Process {
        # Trim trailing backslashes from input paths
        $SourceFolder = $SourceFolder.TrimEnd("\")
        $OutputFolder = $OutputFolder.TrimEnd("\")

        if (Test-Path -Path $SourceFolder) {
            Write-Verbose -Message "Successfully detected specified source folder: $($SourceFolder)"

            if (Test-Path -Path (Join-Path -Path $SourceFolder -ChildPath $SetupFile)) {
                Write-Verbose -Message "Successfully detected specified setup file '$($SetupFile)' in source folder"

                if (Test-Path -Path $OutputFolder) {
                    Write-Verbose -Message "Successfully detected specified output folder: $($OutputFolder)"

                    if (-not(Test-Path -Path $IntuneWinAppUtilPath)) {
                        if (-not($PSBoundParameters["IntuneWinAppUtilPath"])) {
                            # Download IntuneWinAppUtil.exe if not present in context temporary folder
                            Write-Verbose -Message "Unable to detect IntuneWinAppUtil.exe in specified location, attempting to download to: $($env:TEMP)"
                            Start-DownloadFile -URL "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/raw/master/IntuneWinAppUtil.exe" -Path $env:TEMP -Name "IntuneWinAppUtil.exe"

                            # Override path for IntuneWinApputil.exe if custom path was passed as a parameter, but was not found and downloaded to temporary location
                            $IntuneWinAppUtilPath = Join-Path -Path $env:TEMP -ChildPath "IntuneWinAppUtil.exe"
                        }
                    }

                    if (Test-Path -Path $IntuneWinAppUtilPath) {
                        Write-Verbose -Message "Successfully detected IntuneWinAppUtil.exe in: $($IntuneWinAppUtilPath)"

                        # If .intunewin already exists, only continue if Force parameter is passed on command line
                        $ProcessPackage = $true
                        $IntuneWinAppPackage = Join-Path -Path $OutputFolder -ChildPath "$([System.IO.Path]::GetFileNameWithoutExtension($SetupFile)).intunewin"
                        if (Test-Path -Path $IntuneWinAppPackage) {
                            if ($Force) {
                                Write-Verbose -Message "Package file already exist, but Force parameter was specified to overwrite existing file"
                            }
                            else {
                                Write-Warning -Message "Package file already exist, specify the Force parameter to overwrite existing file"
                                $ProcessPackage = $false
                            }
                        }

                        # Continue processing if allowed
                        if ($ProcessPackage -eq $true) {
                            # Invoke IntuneWinAppUtil.exe with parameter inputs
                            Write-Verbose -Message "Invoking IntuneWinAppUtil.exe to initialize packaging process"
                            $PackageInvocation = Invoke-Executable -FilePath $IntuneWinAppUtilPath -Arguments "-c ""$($SourceFolder)"" -s ""$($SetupFile)"" -o ""$($OutPutFolder)"" -q"
                            if ($PackageInvocation.ExitCode -eq 0) {
                                Write-Verbose -Message "IntuneWinAppUtil.exe packaging process completed with exit code $($PackageInvocation.ExitCode)"

                                # Test if .intunewin file exists after packaging process completed
                                if (Test-Path -Path $IntuneWinAppPackage) {
                                    Write-Verbose -Message "Successfully created Win32 app package object"

                                    # Retrieve Win32 app package meta data
                                    $IntuneWinAppMetaData = Get-IntuneWin32AppMetaData -FilePath $IntuneWinAppPackage

                                    # Construct output object with package details
                                    $PSObject = [PSCustomObject]@{
                                        "Name" = $IntuneWinAppMetaData.ApplicationInfo.Name
                                        "FileName" = $IntuneWinAppMetaData.ApplicationInfo.FileName
                                        "SetupFile" = $IntuneWinAppMetaData.ApplicationInfo.SetupFile
                                        "UnencryptedContentSize" = $IntuneWinAppMetaData.ApplicationInfo.UnencryptedContentSize
                                        "Path" = $IntuneWinAppPackage
                                    }
                                    Write-Output -InputObject $PSObject
                                }
                                else {
                                    Write-Warning -Message "Unable to detect expected '$($SetupFile).intunewin' file after IntuneWinAppUtil.exe invocation"
                                }
                            }
                            else {
                                Write-Warning -Message "Unexpect error occurred while packaging Win32 app. Return code from invocation: $($PackageInvocation.ExitCode)"
                            }
                        }
                    }
                    else {
                        Write-Warning -Message "Unable to detect IntuneWinAppUtil.exe in: $($IntuneWinAppUtilPath)"
                    }
                }
                else {
                    Write-Warning -Message "Unable to detect specified output folder: $($OutputFolder)"
                }
            }
            else {
                Write-Warning -Message "Unable to detect specified setup file '$($SetupFile)' in source folder: $($SourceFolder)"
            }
        }
        else {
            Write-Warning -Message "Unable to detect specified source folder: $($SourceFolder)"
        }
    }
}
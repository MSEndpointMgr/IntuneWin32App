function Get-IntuneWin32AppMetaData {
    <#
    .SYNOPSIS
        Retrieves meta data from the detection.xml file inside the packaged Win32 application .intunewin file.

    .DESCRIPTION
        Retrieves meta data from the detection.xml file inside the packaged Win32 application .intunewin file.

    .PARAMETER FilePath
        Specify an existing local path to where the Win32 app .intunewin file is located.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-01-04
        Updated:     2023-01-20

        Version history:
        1.0.0 - (2020-01-04) Function created
        1.0.1 - (2020-06-10) Amended the pattern validation for FilePath parameter to only require a single folder instead of two-level folder structure
        1.0.2 - (2023-01-20) Updated regex pattern for parameter FilePath
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify an existing local path to where the win32 app .intunewin file is located.")]
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
        # Load System.IO.Compression assembly for managing compressed files
        try {
            $ClassImport = Add-Type -AssemblyName "System.IO.Compression.FileSystem" -ErrorAction Stop -Verbose:$false
        }
        catch [System.Exception] {
            Write-Warning -Message "An error occurred while loading System.IO.Compression.FileSystem assembly. Error message: $($_.Exception.Message)"; break
        }
    }
    Process {
        try {
            # Attempt to open compressed .intunewin archive file from parameter input
            $IntuneWin32AppFile = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
    
            # Attempt to extract meta data from .intunewin file
            try {
                if ($IntuneWin32AppFile -ne $null) {
                    # Determine the detection.xml file inside zip archive
                    $DetectionXMLFile = $IntuneWin32AppFile.Entries | Where-Object { $_.Name -like "detection.xml" }
                    
                    # Open the detection.xml file
                    $FileStream = $DetectionXMLFile.Open()
    
                    # Construct new stream reader, pass file stream and read XML content to the end of the file
                    $StreamReader = New-Object -TypeName "System.IO.StreamReader" -ArgumentList $FileStream -ErrorAction Stop
                    $DetectionXMLContent = [xml]($StreamReader.ReadToEnd())
                    
                    # Close and dispose objects to preserve memory usage
                    $FileStream.Close()
                    $StreamReader.Close()
                    $IntuneWin32AppFile.Dispose()
    
                    # Handle return value with XML content from detection.xml
                    return $DetectionXMLContent
                }
            }
            catch [System.Exception] {
                Write-Warning -Message "An error occurred while reading application information from detection.xml file. Error message: $($_.Exception.Message)"
            }
        }
        catch [System.Exception] {
            Write-Warning -Message "An error occurred while attempting to open compressed '$($FilePath)' file. Error message: $($_.Exception.Message)"
        }
    }
}
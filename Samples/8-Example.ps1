# Functions
function Get-LatestGoogleChromeInstaller {
    $ChromeReleasesURI = "https://omahaproxy.appspot.com/all.json"
    $ChromeReleasesContentJSON = Invoke-WebRequest -Uri $ChromeReleasesURI
    $ChromeReleasesContent = $ChromeReleasesContentJSON | ConvertFrom-Json
    $ChromeReleasesOSContent = $ChromeReleasesContent | Where-Object { $_.os -like "win64" }
    foreach ($ChromeVersion in $ChromeReleasesOSContent.versions) {
        if ($ChromeVersion.channel -like "stable") {
            $PSObject = [PSCustomObject]@{
                Version = $ChromeVersion.current_version
                Date = ([DateTime]::ParseExact($ChromeVersion.current_reldate.Trim(), 'MM/dd/yy', [CultureInfo]::InvariantCulture))
                URL = -join@("https://dl.google.com", "/dl/chrome/install/googlechromestandaloneenterprise64.msi")
                FileName = "googlechromestandaloneenterprise64.msi"
            }
            Write-Output -InputObject $PSObject
        }
    }
}

# Authenticate
Connect-MSIntuneGraph -TenantID "tenant.onmicrosoft.com" -Verbose

# Amend these variables
$Publisher = "MSEndpointMgr"
$SourceFolder = "C:\IntuneWin32App\Source\GoogleChrome"
$OutputFolder = "C:\IntuneWin32App\Output"
$AppIconFile = "C:\IntuneWin32App\Icons\Chrome.png"

# Retrieve information for latest Adobe Reader DC setup
$GoogleChromeSetup = Get-LatestGoogleChromeInstaller
Write-Output -InputObject "Latest version of Google Chrome detected as: $($GoogleChromeSetup.Version)"

# Check if latest version is already created in Intune
$GoogleChromeWin32Apps = Get-IntuneWin32App -DisplayName "Chrome" -Verbose
$NewerGoogleChromeWin32Apps = $GoogleChromeWin32Apps | Where-Object { [System.Version]($PSItem.displayName | Select-String -Pattern "(\d+\.)(\d+\.)(\d+\.)(\d+)").Matches.Value -ge [System.Version]$GoogleChromeSetup.Version }

if ($NewerGoogleChromeWin32Apps -eq $null) {
    Write-Output -InputObject "Newer Google Chrome version was not found, creating a new Win32 app for the latest version: $($GoogleChromeSetup.Version)"

    # Define download folder and file paths
    $DownloadDestinationFolderPath = Join-Path -Path $SourceFolder -ChildPath $GoogleChromeSetup.Version
    $DownloadDestinationFilePath = Join-Path -Path $DownloadDestinationFolderPath -ChildPath $GoogleChromeSetup.FileName

    # Create version specific folder if it doesn't exist
    if (-not(Test-Path -Path $DownloadDestinationFolderPath)) {
        Write-Output -InputObject "Couldn't find download path, creating folder: $($DownloadDestinationFolderPath)"
        New-Item -Path $DownloadDestinationFolderPath -ItemType Directory -Force | Out-Null
    }

    # Download the Google Chrome setup file, this generally takes a while
    $WebClient = New-Object -TypeName "System.Net.WebClient"
    Write-Output -InputObject "Starting Google Chrome setup file download, this could take some time"
    $WebClient.DownloadFile($GoogleChromeSetup.URL, $DownloadDestinationFilePath)

    # Create .intunewin package file
    Write-Output -InputObject "Starting Google Chrome encoded packaging process"
    $IntuneWinFile = New-IntuneWin32AppPackage -SourceFolder $DownloadDestinationFolderPath -SetupFile $GoogleChromeSetup.FileName -OutputFolder $OutputFolder -Verbose

    # Create custom display name like 'Name' and 'Version'
    $DisplayName = "Google Chrome" + " " + $GoogleChromeSetup.Version
    Write-Output -InputObject "Constructed display name for Google Chrome Win32 app: $($DisplayName)"

    # Create detection rule using the MSI product code and version
    [string]$ProductCode = Get-MSIMetaData -Path $DownloadDestinationFilePath -Property "ProductCode"
    Write-Output -InputObject "Creating MSI based detection rule"
    $DetectionRule = New-IntuneWin32AppDetectionRuleMSI -ProductCode $ProductCode.Trim() -ProductVersionOperator "greaterThanOrEqual" -ProductVersion $GoogleChromeSetup.Version

    # Create custom requirement rule
    Write-Output -InputObject "Creating default requirement rule for operative system details"
    $RequirementRule = New-IntuneWin32AppRequirementRule -Architecture "All" -MinimumSupportedOperatingSystem "1909"

    # Convert image file to icon
    $Icon = New-IntuneWin32AppIcon -FilePath $AppIconFile

    # Add new MSI Win32 app
    $Win32AppArguments = @{
        "FilePath" = $IntuneWinFile.Path
        "DisplayName" = $DisplayName
        "Description" = "Install the Google Chrome web browser"
        "Publisher" = $Publisher
        "InstallExperience" = "system"
        "RestartBehavior" = "suppress"
        "DetectionRule" = $DetectionRule
        "RequirementRule" = $RequirementRule
        "Icon" = $Icon
        "Verbose" = $true
    }
    Write-Output -InputObject "Starting to create Win32 app in Intune"
    $Win32App = Add-IntuneWin32App @Win32AppArguments

    # Create an available assignment for all users
    Write-Output -InputObject "Adding 'AllUsers' assignment to Win32 app in Intune"
    $Win32AppAssignment = Add-IntuneWin32AppAssignmentAllUsers -ID $Win32App.id -Intent "available" -Notification "showAll" -Verbose

    # Remove .intunewin packaged file
    Remove-Item -Path $IntuneWinFile.Path -Force

    Write-Output -InputObject "Successfully created new Win32 app with name: $($Win32App.displayName)"
}
else {
    Write-Output -InputObject "A newer version of Google Chrome already exists in Intune, will not attempt to create new Win32 app"
}
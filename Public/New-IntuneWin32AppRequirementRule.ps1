function New-IntuneWin32AppRequirementRule {
    <#
    .SYNOPSIS
        Construct a new requirement rule as an optional requirement for Add-IntuneWin32App cmdlet.

    .DESCRIPTION
        Construct a new requirement rule as an optional requirement for Add-IntuneWin32App cmdlet.

    .PARAMETER Architecture
        Specify the architecture as a requirement for the Win32 app. 
        Supported values: x64, x86, arm64, x64x86, AllWithARM64.
        - x64: 64-bit Intel/AMD processors only
        - x86: 32-bit Intel/AMD processors only
        - arm64: 64-bit ARM processors only
        - x64x86: x64 and x86 (Intel/AMD architectures)
        - AllWithARM64: x64, x86, and arm64 (universal)

    .PARAMETER MinimumSupportedWindowsRelease
        Specify the minimum supported Windows release version as a requirement for the Win32 app.

    .PARAMETER MinimumFreeDiskSpaceInMB
        Specify the minimum free disk space in MB as a requirement for the Win32 app.

    .PARAMETER MinimumMemoryInMB
        Specify the minimum required memory in MB as a requirement for the Win32 app.

    .PARAMETER MinimumNumberOfProcessors
        Specify the minimum number of required logical processors as a requirement for the Win32 app.

    .PARAMETER MinimumCPUSpeedInMHz
        Specify the minimum CPU speed in Mhz (as an integer) as a requirement for the Win32 app.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-01-27
        Updated:     2025-12-07

        Version history:
        1.0.0 - (2020-01-27) Function created
        1.0.1 - (2021-03-22) Added new minimum supported operating system versions to parameter validation
        1.0.2 - (2021-08-31) Added new minimum supported operating system versions to parameter validation
        1.0.3 - (2022-09-02) minimumSupportedOperatingSystem property is replaced by minimumSupportedWindowsRelease
        1.0.4 - (2022-10-02) minimumFreeDiskSpaceInMB, MinimumMemoryInMB, MinimumNumberOfProcessors and minimumCpuSpeedInMHz now adds a 'null' string
        1.0.5 - (2023-04-26) Added support for new Windows 10 and Windows 11 minimum operating system versions
        1.0.6 - (2023-09-04) Added alias of MinimumSupportedOperatingSystem to MinimumSupportedWindowsRelease
        1.0.7 - (2025-12-07) BREAKING: Added ARM64 support and switched to modern allowedArchitectures property by default
    #>    
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the architecture as a requirement for the Win32 app.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("x64", "x86", "arm64", "x64x86", "AllWithARM64")]
        [string]$Architecture,

        [parameter(Mandatory = $true, HelpMessage = "Specify the minimum supported Windows release version as a requirement for the Win32 app.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("W10_1607", "W10_1703", "W10_1709", "W10_1803", "W10_1809", "W10_1903", "W10_1909", "W10_2004", "W10_20H2", "W10_21H1", "W10_21H2", "W10_22H2", "W11_21H2", "W11_22H2", "W11_23H2", "W11_24H2")]
        [Alias('MinimumSupportedOperatingSystem')]
        [string]$MinimumSupportedWindowsRelease,

        [parameter(Mandatory = $false, HelpMessage = "Specify the minimum free disk space in MB as a requirement for the Win32 app.")]
        [ValidateNotNullOrEmpty()]
        [int]$MinimumFreeDiskSpaceInMB,

        [parameter(Mandatory = $false, HelpMessage = "Specify the minimum required memory in MB as a requirement for the Win32 app.")]
        [ValidateNotNullOrEmpty()]
        [int]$MinimumMemoryInMB,

        [parameter(Mandatory = $false, HelpMessage = "Specify the minimum number of required logical processors as a requirement for the Win32 app.")]
        [ValidateNotNullOrEmpty()]
        [int]$MinimumNumberOfProcessors,

        [parameter(Mandatory = $false, HelpMessage = "Specify the minimum CPU speed in Mhz (as an integer) as a requirement for the Win32 app.")]
        [ValidateNotNullOrEmpty()]
        [int]$MinimumCPUSpeedInMHz
    )
    Process {
        # Construct table for supported architectures
        $ArchitectureTable = @{
            "x64" = "x64"
            "x86" = "x86"
            "arm64" = "arm64"
            "x64x86" = "x64,x86"
            "AllWithARM64" = "x64,x86,arm64"
        }

        # Construct table for supported operating systems
        $OperatingSystemTable = @{
            "W10_1607" = "1607"
            "W10_1703" = "1703"
            "W10_1709" = "1709"
            "W10_1803" = "1803"
            "W10_1809" = "1809"
            "W10_1903" = "1903"
            "W10_1909" = "1909"
            "W10_2004" = "2004"
            "W10_20H2" = "2H20"
            "W10_21H1" = "21H1"
            "W10_21H2" = "Windows10_21H2"
            "W10_22H2" = "Windows10_22H2"
            "W11_21H2" = "Windows11_21H2"
            "W11_22H2" = "Windows11_22H2"
            "W11_23H2" = "Windows11_23H2"
            "W11_24H2" = "Windows11_24H2"
        }

        # Construct ordered hash-table with least amount of required properties for default requirement rule
        # Using modern allowedArchitectures property with applicableArchitectures set to none
        $RequirementRule = [ordered]@{
            "allowedArchitectures" = $ArchitectureTable[$Architecture]
            "applicableArchitectures" = "none"
            "minimumSupportedWindowsRelease" = $OperatingSystemTable[$MinimumSupportedWindowsRelease]
        }

        # Add additional requirement rule details if specified on command line
        if ($PSBoundParameters["MinimumFreeDiskSpaceInMB"]) {
            $RequirementRule.Add("minimumFreeDiskSpaceInMB", $MinimumFreeDiskSpaceInMB)
        }
        if ($PSBoundParameters["MinimumMemoryInMB"]) {
            $RequirementRule.Add("minimumMemoryInMB", $MinimumMemoryInMB)
        }
        if ($PSBoundParameters["MinimumNumberOfProcessors"]) {
            $RequirementRule.Add("minimumNumberOfProcessors", $MinimumNumberOfProcessors)
        }
        if ($PSBoundParameters["MinimumCPUSpeedInMHz"]) {
            $RequirementRule.Add("minimumCpuSpeedInMHz", $MinimumCPUSpeedInMHz)
        }

        return $RequirementRule
    }
}
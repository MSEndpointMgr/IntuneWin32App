function Invoke-Executable {
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the file name or path of the executable to be invoked, including the extension.")]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [parameter(Mandatory = $false, HelpMessage = "Specify arguments that will be passed to the executable.")]
        [ValidateNotNull()]
        [string]$Arguments,

        [parameter(Mandatory = $false, HelpMessage = "Specify whether standard output should be redirected.")]
        [ValidateNotNull()]
        [bool]$RedirectStandardOutput = $true,

        [parameter(Mandatory = $false, HelpMessage = "Specify whether standard error output should be redirected.")]
        [ValidateNotNull()]
        [bool]$RedirectStandardError = $true,

        [parameter(Mandatory = $false, HelpMessage = "Specify whether to create a new window for the executable.")]
        [ValidateNotNull()]
        [bool]$CreateNoWindow = $true,

        [parameter(Mandatory = $false, HelpMessage = "Specify whether to create a new window for the executable.")]
        [ValidateNotNull()]
        [bool]$UseShellExecute = $false
    )
    try {
        # Create the Process Info object which contains details about the process
        $ProcessStartInfoObject = New-object -TypeName "System.Diagnostics.ProcessStartInfo"
        $ProcessStartInfoObject.FileName = $FilePath
        $ProcessStartInfoObject.CreateNoWindow = $CreateNoWindow
        $ProcessStartInfoObject.UseShellExecute = $UseShellExecute
        $ProcessStartInfoObject.RedirectStandardOutput = $RedirectStandardOutput
        $ProcessStartInfoObject.RedirectStandardError = $RedirectStandardError 
        
        # Add the arguments to the process info object
        if ($Arguments.Count -gt 0) {
            $ProcessStartInfoObject.Arguments = $Arguments
        }

        # Create the object that will represent the process
        $Process = New-Object -TypeName "System.Diagnostics.Process"
        $Process.StartInfo = $ProcessStartInfoObject

        # Start process
        [void]$Process.Start()
        
        # Wait for the process to exit
        $Process.WaitForExit()

        # Return an object that contains the exit code
        return [PSCustomObject]@{
            ExitCode = $Process.ExitCode
        }
    }
    catch [System.Exception] {
        throw "$($MyInvocation.MyCommand): Error message: $($_.Exception.Message)"
    }
}
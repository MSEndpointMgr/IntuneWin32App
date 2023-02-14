function Invoke-Executable {
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the file name or path of the executable to be invoked, including the extension.")]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [parameter(Mandatory = $false, HelpMessage = "Specify arguments that will be passed to the executable.")]
        [ValidateNotNull()]
        [string]$Arguments
    )
    try {
        # Create the Process Info object which contains details about the process
        $ProcessStartInfoObject = New-object System.Diagnostics.ProcessStartInfo 
        $ProcessStartInfoObject.FileName = $FilePath
        $ProcessStartInfoObject.CreateNoWindow = $true 
        $ProcessStartInfoObject.UseShellExecute = $false 
        $ProcessStartInfoObject.RedirectStandardOutput = $true 
        $ProcessStartInfoObject.RedirectStandardError = $true 
        
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
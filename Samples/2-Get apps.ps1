# Retrieve all Win32 apps in Intune
Get-IntuneWin32App -Verbose | Select-Object -Property displayName


# Get a specific Win32 app with a name that starts with '7-zip'
# Performs a sort of wildcard search, e.g. *<string>*
Get-IntuneWin32App -DisplayName "7-zip" -Verbose | Select-Object -Property displayName


# Get a specific Win32 app with a certain ID
Get-IntuneWin32App -ID "efdbf0dd-c99b-49a7-9861-61559c7061b1" -Verbose | Select-Object -Property displayName
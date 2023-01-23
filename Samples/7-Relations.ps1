# Supersedence
$Win32AppLatest = Get-IntuneWin32App -DisplayName "Adobe Reader DC 20.009.20063" -Verbose
$Win32AppPrevious = Get-IntuneWin32App -DisplayName "Adobe Reader DC 20.006.20034" -Verbose
$Supersedence = New-IntuneWin32AppSupersedence -ID $Win32AppPrevious.id -SupersedenceType "Replace" -Verbose # Replace for uninstall, Update for updating
Add-IntuneWin32AppSupersedence -ID $Win32AppLatest.id -Supersedence $Supersedence -Verbose
Get-IntuneWin32AppSupersedence -ID $Win32AppLatest.id -Verbose
Remove-IntuneWin32AppSupersedence -ID $Win32AppLatest.id -Verbose

# Dependency
$Win32App = Get-IntuneWin32App -DisplayName "Adobe Reader DC 20.009.20063" -Verbose
$Win32AppDependency = Get-IntuneWin32App -DisplayName "7-Zip 19.0 x64" -Verbose
$Dependency = New-IntuneWin32AppDependency -ID $Win32AppDependency.id -DependencyType "AutoInstall" -Verbose # Always use AutoInstall
Add-IntuneWin32AppDependency -ID $Win32App.id -Dependency $Dependency -Verbose
Get-IntuneWin32AppDependency -ID $Win32App.id -Verbose
Remove-IntuneWin32AppDependency -ID $Win32App.id -Verbose
# Install IntuneWin32App module from PowerShellGallery
# - Required modules:
# -- MSAL.PS (installed automatically)
Install-Module -Name "IntuneWin32App" -AcceptLicense
Get-InstalledModule -Name "IntuneWin32App"


# Explore the module
Get-Command -Module "IntuneWin32App"


# Retrieve access token required for accessing Microsoft Graph
# Delegated authentication (client authorization and device code flows) are currently supported
Connect-MSIntuneGraph -TenantID "0bb413d7-160d-4839-868a-f3d46537f6af"
Connect-MSIntuneGraph -TenantID "0bb413d7-160d-4839-868a-f3d46537f6af" -Verbose
Connect-MSIntuneGraph -TenantID "0bb413d7-160d-4839-868a-f3d46537f6af" -DeviceCode
Connect-MSIntuneGraph -TenantID "0bb413d7-160d-4839-868a-f3d46537f6af" -Refresh
Connect-MSIntuneGraph -TenantID "0bb413d7-160d-4839-868a-f3d46537f6af" -Interactive


# Access token available in global variable
$Global:AuthenticationHeader
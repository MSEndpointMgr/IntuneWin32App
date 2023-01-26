# Install IntuneWin32App module from PowerShellGallery
# - Required modules:
# -- MSAL.PS (installed automatically)
Install-Module -Name "IntuneWin32App" -AcceptLicense
Get-InstalledModule -Name "IntuneWin32App"


# Explore the module
Get-Command -Module "IntuneWin32App"


# Retrieve access token required for accessing Microsoft Graph
# Delegated authentication (client authorization and device code flows) are currently supported
Connect-MSIntuneGraph -TenantID "tenant.onmicrosoft.com"
Connect-MSIntuneGraph -TenantID "tenant.onmicrosoft.com" -Verbose
Connect-MSIntuneGraph -TenantID "tenant.onmicrosoft.com" -DeviceCode
Connect-MSIntuneGraph -TenantID "tenant.onmicrosoft.com" -Refresh
Connect-MSIntuneGraph -TenantID "tenant.onmicrosoft.com" -Interactive


# Access token available in global variable
$Global:AuthenticationHeader
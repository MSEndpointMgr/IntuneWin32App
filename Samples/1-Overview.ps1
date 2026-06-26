# Install IntuneWin32App module from PowerShellGallery
# - No external dependencies required - all OAuth 2.0 flows implemented natively
Install-Module -Name "IntuneWin32App" -AcceptLicense
Get-InstalledModule -Name "IntuneWin32App"


# Explore the module
Get-Command -Module "IntuneWin32App"


# Retrieve access token required for accessing Microsoft Graph
# All OAuth 2.0 authentication flows are supported natively:

# Interactive authentication (Authorization Code with PKCE)
Connect-MSIntuneGraph -TenantID "tenant.onmicrosoft.com" -ClientID "<ClientID>"

# Device Code flow (for non-interactive environments)
Connect-MSIntuneGraph -TenantID "tenant.onmicrosoft.com" -ClientID "<ClientID>" -DeviceCode

# Client Secret (Service Principal)
Connect-MSIntuneGraph -TenantID "tenant.onmicrosoft.com" -ClientID "<ClientID>" -ClientSecret "<Secret>"

# Client Certificate (Service Principal)
$Cert = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where-Object { $_.Thumbprint -eq "<Thumbprint>" }
Connect-MSIntuneGraph -TenantID "tenant.onmicrosoft.com" -ClientID "<ClientID>" -ClientCert $Cert

# Existing access token
$Token = "<AccessToken>"
Connect-MSIntuneGraph -TenantID "tenant.onmicrosoft.com" -AccessToken $Token

# Refresh existing token
Connect-MSIntuneGraph -TenantID "tenant.onmicrosoft.com" -ClientID "<ClientID>" -Refresh


# Access token available in global variable
$Global:AuthenticationHeader
# Access tokens are renewed silently by the module before each request, for all authentication flows except AccessToken.
# To renew the access token explicitly in long running operations, use the same parameters as when connecting and add -Refresh
if ((Test-AccessToken) -eq $false) {
    Connect-MSIntuneGraph -TenantID $Global:AccessTokenTenantID -ClientID $Global:AccessTokenClientID -Refresh
}

# Add the following if condition in long running operations that require token refresh
if (Test-AccessToken -eq $false) {
    Connect-MSIntuneGraph -TenantID $Global:AccessTokenTenantID -Refresh
}
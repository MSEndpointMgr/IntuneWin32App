function Connect-MSIntuneGraph {
    <#
    .SYNOPSIS
        Connect to Microsoft Intune Graph to retrieve an authentication token required for some functions.

    .DESCRIPTION
        Connect to Microsoft Intune Graph to retrieve an authentication token required for some functions.

    .PARAMETER TenantName
        Specify the tenant name, e.g. domain.onmicrosoft.com.

    .PARAMETER ApplicationID
        Specify the Application ID of the app registration in Azure AD. By default, the script will attempt to use well known Microsoft Intune PowerShell app registration.

    .PARAMETER PromptBehavior
        Set the prompt behavior when acquiring a token.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-09-20
        Updated:     2020-09-20

        Version history:
        1.0.0 - (2020-09-20) Function created

        Required modules:
        AzureAD (Install-Module -Name AzureAD)
        PSIntuneAuth (Install-Module -Name PSIntuneAuth)        
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the tenant name, e.g. domain.onmicrosoft.com.")]
        [ValidateNotNullOrEmpty()]
        [string]$TenantName,
        
        [parameter(Mandatory = $false, HelpMessage = "Specify the Application ID of the app registration in Azure AD. By default, the script will attempt to use well known Microsoft Intune PowerShell app registration.")]
        [ValidateNotNullOrEmpty()]
        [string]$ApplicationID = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547",
    
        [parameter(Mandatory = $false, HelpMessage = "Set the prompt behavior when acquiring a token.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Auto", "Always", "Never", "RefreshSession")]
        [string]$PromptBehavior = "Auto"        
    )
    Begin {
        # Ensure required auth token exists or retrieve a new one
        Get-AuthToken -TenantName $TenantName -ApplicationID $ApplicationID -PromptBehavior $PromptBehavior

        return $Global:AuthToken
    }
}
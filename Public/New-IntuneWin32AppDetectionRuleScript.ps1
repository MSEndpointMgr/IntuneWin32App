function New-IntuneWin32AppDetectionRuleScript {
    <#
    .SYNOPSIS
        Create a new PowerShell script based detection rule object to be used for the Add-IntuneWin32App function.

    .DESCRIPTION
        Create a new PowerShell script based detection rule object to be used for the Add-IntuneWin32App function.

    .PARAMETER ScriptFile
        Specify the full path to the PowerShell detection script, e.g. 'C:\Scripts\Detection.ps1'.

    .PARAMETER EnforceSignatureCheck
        Specify if PowerShell script signature check should be enforced.

    .PARAMETER RunAs32Bit
        Specify if PowerShell script should be executed as a 32-bit process.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2020-09-17
        Updated:     2020-09-17

        Version history:
        1.0.0 - (2020-09-17) Function created
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the full path to the PowerShell detection script, e.g. 'C:\Scripts\Detection.ps1'.")]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptFile,
       
        [parameter(Mandatory = $false, HelpMessage = "Specify if PowerShell script signature check should be enforced.")]
        [ValidateNotNullOrEmpty()]
        [bool]$EnforceSignatureCheck = $false,
       
        [parameter(Mandatory = $false, HelpMessage = "Specify if PowerShell script should be executed as a 32-bit process.")]
        [ValidateNotNullOrEmpty()]
        [bool]$RunAs32Bit = $false
    )
    Process {
        # Handle initial value for return
        $DetectionRule = $null

        # Detect if passed script file exists
        if (Test-Path -Path $ScriptFile) {
            # Convert script file contents to base64 string
            $ScriptContent = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$($ScriptFile)"))

            # Construct detection rule ordered table
            $DetectionRule = [ordered]@{
                "@odata.type" = "#microsoft.graph.win32LobAppPowerShellScriptDetection" ######### Does this really work? "rules" property seems new with new object #microsoft.graph.win32LobAppPowerShellScriptRule
                "enforceSignatureCheck" = $EnforceSignatureCheck
                "runAs32Bit" = $RunAs32Bit
                "scriptContent" = $ScriptContent
            }

            #"rules": [
            #    {
            #        "@odata.type": "#microsoft.graph.win32LobAppPowerShellScriptRule",
            #        "ruleType": "detection",
            #        "displayName": null,
            #        "enforceSignatureCheck": true,
            #        "runAs32Bit": true,
            #        "runAsAccount": null,
            #        "scriptContent": "PCMNCi5TWU5PUFNJUw0KICAgIFByb2FjdGlvbiBSZW1lZGlhdGlvbiBzY3JpcHQgZm9yIENsb3VkTEFQUyBzb2x1dGlvbiB1c2VkIHdpdGhpbiBFbmRwb2ludCBBbmFseXRpY3Mgd2l0aCBNaWNyb3NvZnQgRW5kcG9pbnQgTWFuYWdlciB0byByb3RhdGUgYSBsb2NhbCBhZG1pbmlzdHJhdG9yIHBhc3N3b3JkLg0KDQouREVTQ1JJUFRJT04NCiAgICBUaGlzIGlzIHRoZSBkZXRlY3Rpb24gc2NyaXB0IGZvciBhIFByb2FjdGl2ZSBSZW1lZGlhdGlvbiBpbiBFbmRwb2ludCBBbmFseXRpY3MgdXNlZCBieSB0aGUgQ2xvdWRMQVBTIHNvbHV0aW9uLg0KICAgIA0KICAgIEl0IHdpbGwgY3JlYXRlIGFuIGV2ZW50IGxvZyBuYW1lZCBDbG91ZExBUFMtUm90YXRpb24gaWYgaXQgZG9lc24ndCBhbHJlYWR5IGV4aXN0IGFuZCBlbnN1cmUgdGhlIHJlbWVkaWF0aW9uIHNjcmlwdCBpcyBhbHdheXMgdHJpZ2dlcmVkLg0KDQouRVhBTVBMRQ0KICAgIC5cSW52b2tlLUNsb3VkTEFQU0RldGVjdC5wczENCg0KLk5PVEVTDQogICAgRmlsZU5hbWU6ICAgIEludm9rZS1DbG91ZExBUFNEZXRlY3QucHMxDQogICAgQXV0aG9yOiAgICAgIE5pY2tvbGFqIEFuZGVyc2VuDQogICAgQ29udGFjdDogICAgIEBOaWNrb2xhakENCiAgICBDcmVhdGVkOiAgICAgMjAyMC0wOS0xNA0KICAgIFVwZGF0ZWQ6ICAgICAyMDIwLTA5LTE0DQoNCiAgICBWZXJzaW9uIGhpc3Rvcnk6DQogICAgMS4wLjAgLSAoMjAyMC0wOS0xNCkgU2NyaXB0IGNyZWF0ZWQNCiM+DQpQcm9jZXNzIHsNCiAgICAjIENyZWF0ZSBuZXcgZXZlbnQgbG9nIGlmIGl0IGRvZXNuJ3QgYWxyZWFkeSBleGlzdA0KICAgICRFdmVudExvZ05hbWUgPSAiQ2xvdWRMQVBTLVJvdGF0aW9uIg0KICAgICRFdmVudExvZ1NvdXJjZSA9ICJDbG91ZExBUFMiDQogICAgJENsb3VkTEFQU0V2ZW50TG9nID0gR2V0LVdpbkV2ZW50IC1Mb2dOYW1lICRFdmVudExvZ05hbWUgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWUNCiAgICBpZiAoJENsb3VkTEFQU0V2ZW50TG9nIC1lcSAkbnVsbCkgew0KICAgICAgICB0cnkgew0KICAgICAgICAgICAgTmV3LUV2ZW50TG9nIC1Mb2dOYW1lICRFdmVudExvZ05hbWUgLVNvdXJjZSAkRXZlbnRMb2dTb3VyY2UgLUVycm9yQWN0aW9uIFN0b3ANCiAgICAgICAgfQ0KICAgICAgICBjYXRjaCBbU3lzdGVtLkV4Y2VwdGlvbl0gew0KICAgICAgICAgICAgV3JpdGUtV2FybmluZyAtTWVzc2FnZSAiRmFpbGVkIHRvIGNyZWF0ZSBuZXcgZXZlbnQgbG9nLiBFcnJvciBtZXNzYWdlOiAkKCRfLkV4Y2VwdGlvbi5NZXNzYWdlKSINCiAgICAgICAgfQ0KICAgIH0NCg0KICAgICMgVHJpZ2dlciByZW1lZGlhdGlvbiBzY3JpcHQNCiAgICBleGl0IDENCn0=",
            #        "operationType": "notConfigured",
            #        "operator": "notConfigured",
            #        "comparisonValue": null
            #    }
        }
        else {
            Write-Warning -Message "Unable to detect the presence of specified script file"
        }

        # Handle return value with constructed detection rule
        return $DetectionRule
    }
}
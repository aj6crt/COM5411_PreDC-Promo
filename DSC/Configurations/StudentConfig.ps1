<#
STUDENT TASK:
- Define Configuration StudentBaseline
- Use ConfigurationData (AllNodes.psd1)
- DO NOT hardcode passwords here.

CYBERSECURITY NOTES:
This is a Security module. Credential handling matters even in labs.

WHY NO HARDCODED CREDENTIALS?
1. Security Hygiene: Hardcoded credentials in code = security breach waiting to happen
2. Git History: Once committed, credentials are in your Git history FOREVER (even if you delete them later)
3. Professional Practice: Real environments use credential vaults (Azure KeyVault, HashiCorp Vault, etc.)
4. Audit Trail: Your Git commits may be reviewed by employers, peers, or examiners

HOW CREDENTIALS WILL WORK (Later weeks):
- The orchestrator (Run_BuildMain.ps1) will handle credential creation securely
- Your configuration receives them as PSCredential objects via parameters
- Example: Configuration StudentBaseline { param([PSCredential]$DomainCredential) }
- You reference them in DSC resources without seeing the plaintext password
- MOFs can be encrypted with certificates (production best practice)

FOR NOW (Week 1):
- Lab uses FIXED credentials documented in StudentRepoInit.ps1
- Administrator password: superw1n_user (Windows local admin)
- User accounts password: notlob2k26 (domain users you create)
- You may need these for MANUAL tasks, but NEVER put them in this file

THREAT MODEL AWARENESS:
Even in a lab, practice defense-in-depth:
- Assume your repo will be cloned by others (it will - it's Git!)
- Assume your transcripts/logs will be read (they're in Evidence/)
- Assume your build artifacts will be inspected (they're committed)
- NEVER commit: passwords, API keys, personal data, PII

If you accidentally commit a secret:
1. Rotating the secret is the ONLY fix (changing the password)
2. Deleting the file or "fixing" the commit does NOT remove it from Git history
3. Tools like git-secrets, TruffleHog, and GitGuardian scan for exposed secrets

This is not paranoia - this is professional discipline.
#>



Configuration StudentBaseline {
    param(
        [PSCredential]$DomainAdminCredential,
        [PSCredential]$DsrmCredential,
        [PSCredential]$UserCredential
    )

    # These imports are required for the resources used below
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName NetworkingDsc

    Node $AllNodes.NodeName {
        
        # --- Networking ---
        IPAddress InternalStaticIP {
            InterfaceAlias = $Node.InterfaceAlias_Internal
            AddressFamily  = 'IPv4'
            IPAddress      = $Node.IPv4Address_Internal 
        }

        DNSServerAddress InternalDNS {
            InterfaceAlias = $Node.InterfaceAlias_Internal
            AddressFamily  = 'IPv4'
            Address        = $Node.DnsServers_Internal 
            DependsOn      = '[IPAddress]InternalStaticIP'
        }

        # Fixes the NAT NIC registration failure in Pester
        DnsClient DisableNatRegistration 
        {
            InterfaceAlias                 = $Node.InterfaceAlias_NAT
            RegisterThisConnectionsAddress = $false
            DependsOn                      = '[WindowsFeature]RSATADDS'
        }

        # Ensures the Domain Controller uses the correct DNS suffix
        DnsClientGlobalSetting SuffixPreference 
        {
            IsSingleInstance = 'Yes'
            SuffixSearchList = @($Node.DomainName)
            DependsOn        = '[WindowsFeature]RSATADDS'
        }

        # --- Active Directory ---
        WindowsFeature ADDS {
            Name   = 'AD-Domain-Services'
            Ensure = 'Present'
        }

        WindowsFeature RSATADDS {
            Name   = 'RSAT-AD-Tools'
            Ensure = 'Present'
        }

        ADDomain BarmBuzzDomain {
            DomainName                    = $Node.DomainName
            DomainNetbiosName             = $Node.DomainNetBIOSName
            DomainMode                    = $Node.DomainMode
            ForestMode                    = $Node.ForestMode
            Credential                    = $DomainAdminCredential 
            SafeModeAdministratorPassword = $DsrmCredential
            DependsOn                     = @('[WindowsFeature]ADDS', '[DNSServerAddress]InternalDNS')
        }
    }
}
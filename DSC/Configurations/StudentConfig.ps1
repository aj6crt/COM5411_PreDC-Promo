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

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName NetworkingDsc

    Node $AllNodes.NodeName {

        # Set the computer name
        Computer SetComputerName {
            Name = $Node.ComputerName
        }

        # Set The Timezone
        TimeZone SetTimeZone {
            IsSingleInstance = 'Yes'
            TimeZone = $Node.TimeZone
        }

        ### Network Settings - Internal NIC
        IPAddress SetInternalIP {
            InterfaceAlias = $Node.InterfaceAlias_Internal
            AddressFamily  = 'IPv4'
            IPAddress      = $Node.IPv4Address_Internal
            # FIXED: Now matches the 'SetComputerName' resource name above
            DependsOn = '[Computer]SetComputerName'
        }

        DnsServerAddress SetInternalDns {
            InterfaceAlias = $Node.InterfaceAlias_Internal
            AddressFamily  = 'IPv4'
            Address        = $Node.DNSServers_Internal
            DependsOn      = '[IPAddress]SetInternalIP'
        }

        ### Network Settings -- External NIC
        DnsConnectionSuffix DisableNatDnsRegistration {
            InterfaceAlias            = $Node.InterfaceAlias_NAT
            ConnectionSpecificSuffix = ''
            RegisterThisConnectionsAddress = $false
            DependsOn = '[DnsServerAddress]SetInternalDns'
        }

        Service WindowsTime {
            Name        = 'W32Time'
            State       = 'Running'
            StartupType = 'Automatic'
            DependsOn   = '[TimeZone]SetTimeZone'
        }

       if ($Node.InstallADDSRole) {
            WindowsFeature ADDS {
                Name   = 'AD-Domain-Services'
                Ensure = 'Present'
            }
        }

        if ($Node.InstallRSATADDS) {
            WindowsFeature RSAT-ADDS {
                Name      = 'RSAT-ADDS'
                Ensure    = 'Present'
                DependsOn = '[WindowsFeature]ADDS'
            }
        }

        ### PROMOTE TO DOMAIN CONTROLLER
        ADDomain CreateForest {
            DomainName                    = $Node.DomainName
            DomainNetBIOSName             = $Node.DomainNetBIOSName
            Credential                    = $DomainAdminCredential
            SafemodeAdministratorPassword = $DsrmCredential
            ForestMode                    = $Node.ForestMode
            DomainMode                    = $Node.DomainMode
            # FIXED: Now matches the 'RSAT-ADDS' resource name above
            DependsOn = '[WindowsFeature]RSAT-ADDS'
        }
    }
}


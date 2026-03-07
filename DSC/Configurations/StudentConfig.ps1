Configuration StudentBaseline {
    param(
        [PSCredential]$DomainAdminCredential,
        [PSCredential]$DsrmCredential,
        [PSCredential]$UserCredential
    )

    # FIX: Added NetworkingDsc to resolve 'ResourceNotDefined'
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DscResource -ModuleName ActiveDirectoryDsc
    # FIX: Use the Fully Qualified name to bypass the "Multiple Versions" error
    Import-DscResource -ModuleName NetworkingDsc -ModuleVersion 9.1.0
    Import-DscResource -ModuleName GroupPolicyDsc

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

        # FIX: Resolves Pester failure for NAT Registration

        # FIX: Required for DNS suffix best practices
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
            Name   = 'RSAT-ADDS'
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
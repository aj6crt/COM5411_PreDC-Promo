@{
    AllNodes = @(
        @{
            NodeName                    = 'localhost'
            Role                        = 'DC'
            ComputerName                = 'BB-DC01'

            DomainName                  = 'barmbuzz.local'
            DomainNetBIOSName           = 'BARMBUZZ'
            ForestMode                  = 'WinThreshold' 
            DomainMode                  = 'WinThreshold'

            TimeZone                    = 'GMT Standard Time'
            EnsureW32Time               = $true

            InterfaceAlias_Internal     = 'Ethernet 2'
            IPv4Address_Internal        = '192.168.1.10'
            PrefixLength_Internal       = 24
            DefaultGateway_Internal     = '' 
            DNSServers_Internal         = @('127.0.0.1')
            
            InterfaceAlias_NAT          = 'Ethernet'
            Expect_NAT_Dhcp             = $true
            DisableDnsRegistrationOnNat = $true
            InstallADDSRole             = $true
            InstallRSATADDS             = $true
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true
        }
    )
}
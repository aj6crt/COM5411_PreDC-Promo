@{
    AllNodes = @(
        @{
            NodeName     = 'localhost'
            Role         = 'DC'

            ## AD Settings
            DomainName          = 'barmbuzz.local'
            DomainNetBIOSName   = 'BARMBUZZ'
            ForestMode          = 'WinThreshold'
            DomainMode          = 'WinThreshold'

            ## Computer Settings
            ComputerName        = 'BB-DC01'
            TimeZone            = 'GMT Standard Time'
            EnsureW32Time       = 'true'

            ## Network Settings - Internal NIC
            InterfaceAlias_Internal   = 'Ethernet 2'
            IPv4Address_Internal      = '192.168.1.10'
            PrefixLength_Internal     = 24
            DefaultGateway_Internal   = ''
            DNSServers_Internal       = @('127.0.0.1')

            ## Network Settings - External NIC
            InterfaceAlias_NAT        = 'Ethernet'
            Expect_NAT_Dhcp           = 'true'
            DisableDnsRegistrationOnNat = 'true'

            ## Feature Installation Flags
            InstallADDSRole           = 'true'
            InstallRSATADDS           = 'true'

            ## Security Settings
            PsDscAllowPlainTextPassword = 'true'
            PsDscAllowDomainUser        = 'true'

            # SECURITY NOTE: Future credential properties will be added by the orchestrator
            # at runtime, not stored here. Example (YOU DON'T ADD THIS YET):
            # DomainCredential = $PSCredentialObject  # Injected by Run_BuildMain.ps1

            # CERTIFICATE ENCRYPTION (Production pattern - informational for now):
            # CertificateFile = 'C:\Certs\DscPublicKey.cer'  # Public key for MOF encryption
            # Thumbprint = '1234567890ABCDEF...'            # Certificate thumbprint
            # PsDscAllowPlainTextPassword = $false           # Force encryption (production)
        }
    )
}
@{
    AllNodes = @(
        @{
            # --- Node Identity & Role ---
            NodeName                    = 'localhost'
            Role                        = 'DC'
            ComputerName                = 'BB-DC01'
            DomainName                  = 'barmbuzz.local' 
            DomainNetBIOSName           = 'BARMBUZZ'
            ForestMode                  = 'WinThreshold' 
            DomainMode                  = 'WinThreshold'
            DomainDN                    = 'DC=barmbuzz,DC=corp'

            # --- Network & Logical Site Mapping [cite: 115, 204] ---
            InterfaceAlias_Internal     = 'Ethernet 2'
            IPv4Address_Internal        = '192.168.1.10'
            DNSServers_Internal         = @('127.0.0.1')

            ADSites = @(
                [cite_start]@{ Name = 'Bolton'; Description = 'Global HQ & Forest Root' } [cite: 142]
                @{ Name = 'Leeds';  [cite_start]Description = 'Regional Subsidiary' } [cite: 115]
                @{ Name = 'Stoke';  Description = 'Regional Branch' }
            )

            ADSubnets = @(
                @{ Name = '192.168.1.0/24'; Site = 'Bolton' }
                @{ Name = '192.168.2.0/24'; Site = 'Leeds' }
                @{ Name = '192.168.3.0/24'; Site = 'Stoke' }
            )

            # --- Domain Password Policy ---
            PasswordPolicy = @{
                ComplexityEnabled           = $true
                MinPasswordLength           = 10
                PasswordHistoryCount        = 12
                MaxPasswordAge              = 129600    # 90 days
                MinPasswordAge              = 1440      # 1 day
                LockoutThreshold            = 5
                LockoutDuration             = 30        # 30 minutes
                LockoutObservationWindow    = 30        # 30 minutes
                ReversibleEncryptionEnabled = $false
            }

            # --- Organizational Unit Hierarchy [cite: 204, 206] ---
            OrganizationalUnits = @(
                @{ Key = 'BarmBuzz'; Name = 'BarmBuzz'; ParentPath = ''; Protected = $true } 
                @{ Key = 'Tier0'; Name = 'Tier0'; ParentPath = 'OU=BarmBuzz'; Protected = $true; DependsOnKey = 'BarmBuzz' }
                @{ Key = 'Sites'; Name = 'Sites'; ParentPath = 'OU=BarmBuzz'; Protected = $true; DependsOnKey = 'BarmBuzz' }
                # Site: Bolton
                @{ Key = 'Bolton'; Name = 'Bolton'; ParentPath = 'OU=Sites,OU=BarmBuzz'; Protected = $true; DependsOnKey = 'Sites' }
                @{ Key = 'Bolton_Users'; Name = 'Users'; ParentPath = 'OU=Bolton,OU=Sites,OU=BarmBuzz'; Protected = $true; DependsOnKey = 'Bolton' }
                @{ Key = 'Bolton_Workstations'; Name = 'Workstations'; ParentPath = 'OU=Bolton,OU=Sites,OU=BarmBuzz'; Protected = $true; DependsOnKey = 'Bolton' }
                # Site: Leeds
                @{ Key = 'Leeds'; Name = 'Leeds'; ParentPath = 'OU=Sites,OU=BarmBuzz'; Protected = $true; DependsOnKey = 'Sites' }
                @{ Key = 'Leeds_Users'; Name = 'Users'; ParentPath = 'OU=Leeds,OU=Sites,OU=BarmBuzz'; Protected = $true; DependsOnKey = 'Leeds' }
                # Site: Stoke
                @{ Key = 'Stoke'; Name = 'Stoke'; ParentPath = 'OU=Sites,OU=BarmBuzz'; Protected = $true; DependsOnKey = 'Sites' }
                @{ Key = 'Stoke_Users'; Name = 'Users'; ParentPath = 'OU=Stoke,OU=Sites,OU=BarmBuzz'; Protected = $true; DependsOnKey = 'Stoke' }
                # Shared Groups
                @{ Key = 'Groups'; Name = 'Groups'; ParentPath = 'OU=BarmBuzz'; Protected = $true; DependsOnKey = 'BarmBuzz' }
                @{ Key = 'Groups_Role'; Name = 'Role'; ParentPath = 'OU=Groups,OU=BarmBuzz'; Protected = $true; DependsOnKey = 'Groups' }
            )

            # --- RBAC & Security Groups [cite: 259] ---
            SecurityGroups = @(
                @{ Key = 'GG_IT_Helpdesk'; GroupName = 'GG_BB_IT_Helpdesk'; GroupScope = 'Global'; Category = 'Security'; OUPath = 'OU=Role,OU=Groups,OU=BarmBuzz'; DependsOnOUKey = 'Groups_Role' }
                @{ Key = 'GG_Bolton_Baristas'; GroupName = 'GG_BB_Bolton_Baristas'; GroupScope = 'Global'; Category = 'Security'; OUPath = 'OU=Role,OU=Groups,OU=BarmBuzz'; DependsOnOUKey = 'Groups_Role' }
                @{ Key = 'GG_Leeds_Baristas'; GroupName = 'GG_BB_Leeds_Baristas'; GroupScope = 'Global'; Category = 'Security'; OUPath = 'OU=Role,OU=Groups,OU=BarmBuzz'; DependsOnOUKey = 'Groups_Role' }
                @{ Key = 'GG_Stoke_Baristas'; GroupName = 'GG_BB_Stoke_Baristas'; GroupScope = 'Global'; Category = 'Security'; OUPath = 'OU=Role,OU=Groups,OU=BarmBuzz'; DependsOnOUKey = 'Groups_Role' }
            )

            # --- GPO Registry Hardening ---
            GPORegistryValues = @(
                @{ Key = 'Wks_NoLMHash'; GPOName = 'BB_Workstations_Baseline'; RegistryKey = 'HKLM\System\CurrentControlSet\Control\Lsa'; ValueName = 'NoLMHash'; ValueType = 'DWord'; ValueData = '1' }
                @{ Key = 'Srv_AuditLogSize'; GPOName = 'BB_Servers_Baseline'; RegistryKey = 'HKLM\System\CurrentControlSet\Services\EventLog\Security'; ValueName = 'MaxSize'; ValueType = 'DWord'; ValueData = '1048576' }
                @{ Key = 'Banner_Text'; GPOName = 'BB_AllUsers_Banner'; RegistryKey = 'HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System'; ValueName = 'LegalNoticeText'; ValueType = 'String'; ValueData = 'This system is property of BarmBuzz. Unauthorised access prohibited.' }
            )

            # --- AD Users [cite: 266] ---
            ADUsers = @(
                @{ Key = 'ava_barista'; UserName = 'ava.barista'; UserPrincipalName = 'ava.barista@barmbuzz.corp'; OUPath = 'OU=Users,OU=Bolton,OU=Sites,OU=BarmBuzz'; DependsOnOUKey = 'Bolton_Users'; GroupMembership = @('GG_BB_Bolton_Baristas') }
                @{ Key = 'leo_barista'; UserName = 'leo.barista'; UserPrincipalName = 'leo.barista@barmbuzz.corp'; OUPath = 'OU=Users,OU=Leeds,OU=Sites,OU=BarmBuzz'; DependsOnOUKey = 'Leeds_Users'; GroupMembership = @('GG_BB_Leeds_Baristas') }
                @{ Key = 'stacy_barista'; UserName = 'stacy.barista'; UserPrincipalName = 'stacy.barista@barmbuzz.corp'; OUPath = 'OU=Users,OU=Stoke,OU=Sites,OU=BarmBuzz'; DependsOnOUKey = 'Stoke_Users'; GroupMembership = @('GG_BB_Stoke_Baristas') }
            )

            # --- Permission Delegations ---
            Delegations = @(
                @{ Key = 'Delegate_Workstation_Join'; TargetOUPath = 'OU=Workstations,OU=Bolton,OU=Sites,OU=BarmBuzz'; IdentityGroupName = 'GG_BB_IT_Helpdesk'; DependsOnOUKey = 'Bolton_Workstations'; DependsOnGroupKey = 'GG_IT_Helpdesk'; Rights = @('CreateChild', 'DeleteChild'); AccessControlType = 'Allow'; ObjectTypeGuid = 'bf967a86-0de6-11d0-a285-00aa003049e2'; InheritanceType = 'All'; InheritedObjectType = '00000000-0000-0000-0000-000000000000' }
            )
        }
    )
}
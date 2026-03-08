AllNodes = @(
    @{
        # --- Identity & Infrastructure Requirements ---
        NodeName                    = 'localhost'
        PSDscAllowPlainTextPassword = $true
        Role                        = 'DC'
        ComputerName                = 'BB-DC01'
        TimeZone                    = 'GMT Standard Time'
        DomainName                  = 'barmbuzz.local'
        DomainNetBIOSName           = 'BARMBUZZ'
        ForestMode                  = 'WinThreshold'
        DomainMode                  = 'WinThreshold'
        DomainDN                    = 'DC=barmbuzz,DC=corp'

        # --- Network Infrastructure ---
        InterfaceAlias_Internal     = 'Ethernet 2'
        InterfaceAlias_NAT          = 'Ethernet'
        IPv4Address_Internal        = '192.168.1.10'
        PrefixLength_Internal       = 24
        DnsServers_Internal         = @('127.0.0.1')
        Expect_NAT_Dhcp             = $true
        DisableDnsRegistrationOnNat = $true
        InstallADDSRole             = $true
        InstallRSATADDS             = $true

        # --- Organizational Structure ---
        OrgName   = 'BarmBuzz'
        OrgPrefix = 'BB'

        OrganizationalUnits = @(
            @{ Key = 'BarmBuzz'; Name = 'BarmBuzz'; ParentPath = ''; DependsOnKey = $null; Protected = $true; Description = 'BarmBuzz enterprise root' }
            @{ Key = 'Tier0'; Name = 'Tier0'; ParentPath = 'OU=BarmBuzz'; DependsOnKey = 'BarmBuzz'; Protected = $true; Description = 'Domain control plane' }
            @{ Key = 'Tier0_Admins'; Name = 'Admins'; ParentPath = 'OU=Tier0,OU=BarmBuzz'; DependsOnKey = 'Tier0'; Protected = $true; Description = 'Domain administrators' }
            @{ Key = 'Tier0_Servers'; Name = 'Servers'; ParentPath = 'OU=Tier0,OU=BarmBuzz'; DependsOnKey = 'Tier0'; Protected = $true; Description = 'Domain infrastructure servers' }
            @{ Key = 'Sites'; Name = 'Sites'; ParentPath = 'OU=BarmBuzz'; DependsOnKey = 'BarmBuzz'; Protected = $true; Description = 'Geographic sites' }
            @{ Key = 'Bolton'; Name = 'Bolton'; ParentPath = 'OU=Sites,OU=BarmBuzz'; DependsOnKey = 'Sites'; Protected = $true; Description = 'Bolton HQ - Site Root' }
            @{ Key = 'Bolton_Users'; Name = 'Users'; ParentPath = 'OU=Bolton,OU=Sites,OU=BarmBuzz'; DependsOnKey = 'Bolton'; Protected = $true; Description = 'Bolton staff users' }
            @{ Key = 'Bolton_Computers'; Name = 'Computers'; ParentPath = 'OU=Bolton,OU=Sites,OU=BarmBuzz'; DependsOnKey = 'Bolton'; Protected = $true; Description = 'Bolton computer accounts' }
            @{ Key = 'Bolton_Workstations'; Name = 'Workstations'; ParentPath = 'OU=Computers,OU=Bolton,OU=Sites,OU=BarmBuzz'; DependsOnKey = 'Bolton_Computers'; Protected = $true; Description = 'Staff workstations' }
            @{ Key = 'Bolton_POS'; Name = 'POS'; ParentPath = 'OU=Computers,OU=Bolton,OU=Sites,OU=BarmBuzz'; DependsOnKey = 'Bolton_Computers'; Protected = $true; Description = 'POS terminals' }
            @{ Key = 'Groups'; Name = 'Groups'; ParentPath = 'OU=BarmBuzz'; DependsOnKey = 'BarmBuzz'; Protected = $true; Description = 'Security and distribution groups' }
            @{ Key = 'Groups_Role'; Name = 'Role'; ParentPath = 'OU=Groups,OU=BarmBuzz'; DependsOnKey = 'Groups'; Protected = $true; Description = 'Global role groups' }
            @{ Key = 'Groups_Resource'; Name = 'Resource'; ParentPath = 'OU=Groups,OU=BarmBuzz'; DependsOnKey = 'Groups'; Protected = $true; Description = 'Domain local resource groups' }
        )

        # --- Password Policy ---
        PasswordPolicy = @{
            ComplexityEnabled           = $true
            MinPasswordLength           = 10
            PasswordHistoryCount        = 12
            MaxPasswordAge              = 129600 # 90 days
            MinPasswordAge              = 1440   # 1 day
            LockoutThreshold            = 5
            LockoutDuration             = 30
            LockoutObservationWindow    = 30
            ReversibleEncryptionEnabled = $false
        }

        # --- Security Groups (AGDLP Model) ---
        SecurityGroups = @(
            @{ Key = 'GG_Bolton_Baristas'; GroupName = 'GG_BB_Bolton_Baristas'; GroupScope = 'Global'; Category = 'Security' }
            @{ Key = 'GG_Bolton_Managers'; GroupName = 'GG_BB_Bolton_Managers'; GroupScope = 'Global'; Category = 'Security' }
            @{ Key = 'GG_IT_Helpdesk'; GroupName = 'GG_BB_IT_Helpdesk'; GroupScope = 'Global'; Category = 'Security' }
            @{ Key = 'DL_POS_LocalAdmins'; GroupName = 'DL_BB_POS_LocalAdmins'; GroupScope = 'DomainLocal'; Category = 'Security' }
            @{ Key = 'DL_Recipes_Read'; GroupName = 'DL_BB_Recipes_Read'; GroupScope = 'DomainLocal'; Category = 'Security' }
            @{ Key = 'DL_Recipes_Write'; GroupName = 'DL_BB_Recipes_Write'; GroupScope = 'DomainLocal'; Category = 'Security' }
        )

        # --- Active Directory Users ---
        ADUsers = @(
            @{
                Key = 'ava_barista'; UserName = 'ava.barista'; GivenName = 'Ava'; Surname = 'Barista'; DisplayName = 'Ava Barista'
                UserPrincipalName = 'ava.barista@barmbuzz.corp'; OUPath = 'OU=Users,OU=Bolton,OU=Sites,OU=BarmBuzz'
                DependsOnOUKey = 'Bolton_Users'; GroupMembership = @('GG_BB_Bolton_Baristas'); JobTitle = 'Senior Barista'
                Department = 'Barm Assembly'; Description = 'Bolton barista - HVBSDP certified'; ChangePasswordAtLogon = $true
            }
            @{
                Key = 'bob_manager'; UserName = 'bob.manager'; GivenName = 'Bob'; Surname = 'Manager'; DisplayName = 'Bob Manager'
                UserPrincipalName = 'bob.manager@barmbuzz.corp'; OUPath = 'OU=Users,OU=Bolton,OU=Sites,OU=BarmBuzz'
                DependsOnOUKey = 'Bolton_Users'; GroupMembership = @('GG_BB_Bolton_Managers'); JobTitle = 'Depot Manager'
                Department = 'Operations'; Description = 'Bolton depot manager - route supervisor'; ChangePasswordAtLogon = $true
            }
            @{
                Key = 'charlie_helpdesk'; UserName = 'charlie.helpdesk'; GivenName = 'Charlie'; Surname = 'Helpdesk'; DisplayName = 'Charlie Helpdesk'
                UserPrincipalName = 'charlie.helpdesk@barmbuzz.corp'; OUPath = 'OU=Users,OU=Bolton,OU=Sites,OU=BarmBuzz'
                DependsOnOUKey = 'Bolton_Users'; GroupMembership = @('GG_BB_IT_Helpdesk'); JobTitle = 'IT Helpdesk Analyst'
                Department = 'IT'; Description = 'IT helpdesk - delegated workstation and user support'; ChangePasswordAtLogon = $true
            }
        )

        # --- Delegation Entries ---
        Delegations = @(
            @{
                Key                 = 'Delegate_Workstation_Join'
                TargetOUPath        = 'OU=Workstations,OU=Computers,OU=Bolton,OU=Sites,OU=BarmBuzz'
                IdentityGroupName   = 'GG_BB_IT_Helpdesk'
                DependsOnOUKey      = 'Bolton_Workstations'
                DependsOnGroupKey   = 'GG_IT_Helpdesk'
                Rights              = @('CreateChild', 'DeleteChild')
                AccessControlType   = 'Allow'
                ObjectTypeGuid      = 'bf967a86-0de6-11d0-a285-00aa003049e2'
                InheritanceType     = 'All'
                InheritedObjectType = '00000000-0000-0000-0000-000000000000'
                Description         = 'Allow IT Helpdesk to join/remove workstations in Bolton'
            }
        )

        # --- Group Policy Management ---
        GroupPolicies = @(
            @{ Key = 'GPO_Workstations_Baseline'; Name = 'BB_Workstations_Baseline'; Description = 'BarmBuzz workstation security baseline - LM hash, SMB signing, screensaver' }
            @{ Key = 'GPO_Servers_Baseline'; Name = 'BB_Servers_Baseline'; Description = 'BarmBuzz server hardening baseline - audit log, SMBv1 disable' }
            @{ Key = 'GPO_POS_Lockdown'; Name = 'BB_POS_Lockdown'; Description = 'POS terminal lockdown - USB restrictions, logon banner, enforced' }
            @{ Key = 'GPO_AllUsers_Banner'; Name = 'BB_AllUsers_Banner'; Description = 'Organisation-wide logon banner - legal notice, acceptable use' }
        )

        GPOLinks = @(
            @{ Key = 'Link_WksBaseline_Workstations'; GPOName = 'BB_Workstations_Baseline'; TargetOUPath = 'OU=Workstations,OU=Computers,OU=Bolton,OU=Sites,OU=BarmBuzz'; DependsOnGPO = 'GPO_Workstations_Baseline'; DependsOnOUKey = 'Bolton_Workstations'; Order = 1; Enforced = 'No'; LinkEnabled = 'Yes' }
            @{ Key = 'Link_SrvBaseline_Servers'; GPOName = 'BB_Servers_Baseline'; TargetOUPath = 'OU=Servers,OU=Tier0,OU=BarmBuzz'; DependsOnGPO = 'GPO_Servers_Baseline'; DependsOnOUKey = 'Tier0_Servers'; Order = 1; Enforced = 'No'; LinkEnabled = 'Yes' }
            @{ Key = 'Link_POSLockdown_POS'; GPOName = 'BB_POS_Lockdown'; TargetOUPath = 'OU=POS,OU=Computers,OU=Bolton,OU=Sites,OU=BarmBuzz'; DependsOnGPO = 'GPO_POS_Lockdown'; DependsOnOUKey = 'Bolton_POS'; Order = 1; Enforced = 'Yes'; LinkEnabled = 'Yes' }
            @{ Key = 'Link_Banner_BarmBuzz'; GPOName = 'BB_AllUsers_Banner'; TargetOUPath = 'OU=BarmBuzz'; DependsOnGPO = 'GPO_AllUsers_Banner'; DependsOnOUKey = 'BarmBuzz'; Order = 1; Enforced = 'No'; LinkEnabled = 'Yes' }
        )

        GPORegistryValues = @(
            # -- Workstation Baseline --
            @{ Key = 'Wks_NoLMHash'; GPOName = 'BB_Workstations_Baseline'; DependsOnGPO = 'GPO_Workstations_Baseline'; RegistryKey = 'HKLM\System\CurrentControlSet\Control\Lsa'; ValueName = 'NoLMHash'; ValueType = 'DWord'; ValueData = '1'; Description = 'Disable LM hash storage - prevents weak hash creation' }
            @{ Key = 'Wks_SMBSigning'; GPOName = 'BB_Workstations_Baseline'; DependsOnGPO = 'GPO_Workstations_Baseline'; RegistryKey = 'HKLM\System\CurrentControlSet\Services\LanManServer\Parameters'; ValueName = 'RequireSecuritySignature'; ValueType = 'DWord'; ValueData = '1'; Description = 'Require SMB signing - prevents relay attacks' }
            @{ Key = 'Wks_NTLMv2Only'; GPOName = 'BB_Workstations_Baseline'; DependsOnGPO = 'GPO_Workstations_Baseline'; RegistryKey = 'HKLM\System\CurrentControlSet\Control\Lsa'; ValueName = 'LmCompatibilityLevel'; ValueType = 'DWord'; ValueData = '5'; Description = 'NTLMv2 only - refuse LM and NTLMv1' }
            @{ Key = 'Wks_ScreenSaver'; GPOName = 'BB_Workstations_Baseline'; DependsOnGPO = 'GPO_Workstations_Baseline'; RegistryKey = 'HKCU\Control Panel\Desktop'; ValueName = 'ScreenSaveTimeOut'; ValueType = 'String'; ValueData = '600'; Description = 'Screen saver timeout 10 min - unattended session lock' }
            
            # -- Server Baseline --
            @{ Key = 'Srv_AuditLogSize'; GPOName = 'BB_Servers_Baseline'; DependsOnGPO = 'GPO_Servers_Baseline'; RegistryKey = 'HKLM\System\CurrentControlSet\Services\EventLog\Security'; ValueName = 'MaxSize'; ValueType = 'DWord'; ValueData = '1048576'; Description = 'Security event log 1GB - sufficient for DC audit trail' }
            @{ Key = 'Srv_SMB1Disable'; GPOName = 'BB_Servers_Baseline'; DependsOnGPO = 'GPO_Servers_Baseline'; RegistryKey = 'HKLM\System\CurrentControlSet\Services\LanmanServer\Parameters'; ValueName = 'SMB1'; ValueType = 'DWord'; ValueData = '0'; Description = 'Disable SMBv1 - WannaCry prevention, protocol hygiene' }
            
            # -- POS Lockdown --
            @{ Key = 'POS_NoUSB'; GPOName = 'BB_POS_Lockdown'; DependsOnGPO = 'GPO_POS_Lockdown'; RegistryKey = 'HKLM\System\CurrentControlSet\Services\USBSTOR'; ValueName = 'Start'; ValueType = 'DWord'; ValueData = '4'; Description = 'Disable USB storage - prevent data exfiltration from POS terminals' }
            @{ Key = 'POS_LogonBanner'; GPOName = 'BB_POS_Lockdown'; DependsOnGPO = 'GPO_POS_Lockdown'; RegistryKey = 'HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System'; ValueName = 'LegalNoticeText'; ValueType = 'String'; ValueData = 'BarmBuzz POS Terminal - Authorised use only. All activity is monitored.'; Description = 'Logon banner - legal notice for POS terminals' }
            
            # -- Organisation-Wide Banner --
            @{ Key = 'Banner_Title'; GPOName = 'BB_AllUsers_Banner'; DependsOnGPO = 'GPO_AllUsers_Banner'; RegistryKey = 'HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System'; ValueName = 'LegalNoticeCaption'; ValueType = 'String'; ValueData = 'BarmBuzz Corp - Acceptable Use Policy'; Description = 'Logon banner title - organisation-wide legal notice' }
            @{ Key = 'Banner_Text'; GPOName = 'BB_AllUsers_Banner'; DependsOnGPO = 'GPO_AllUsers_Banner'; RegistryKey = 'HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System'; ValueName = 'LegalNoticeText'; ValueType = 'String'; ValueData = 'This system is the property of BarmBuzz Corp. Unauthorised access is prohibited. All activity is logged and monitored.'; Description = 'Logon banner body - legal compliance and deterrence' }
        )

        GPOPermissions = @(
            @{
                Key          = 'Perm_POS_Baristas'
                GPOName      = 'BB_POS_Lockdown'
                DependsOnGPO = 'GPO_POS_Lockdown'
                TargetName   = 'GG_BB_Bolton_Baristas'
                TargetType   = 'Group'
                Permission   = 'GpoApply'
            }
        )
    }
)
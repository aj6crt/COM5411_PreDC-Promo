Configuration BarmBuzz_Final_Build {
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName NetworkingDsc
    Import-DscResource -ModuleName ComputerManagementDsc

    Node $AllNodes.NodeName {

        # 1. Rename and Network Prep
        ComputerManagementDsc\ComputerName RenameNode {
            ComputerName = $Node.ComputerName
        }

        NetworkingDsc\IPAddress InternalIP {
            InterfaceAlias = $Node.InterfaceAlias_Internal
            IPAddress      = $Node.IPv4Address_Internal
            PrefixLength   = $Node.PrefixLength_Internal
            AddressFamily  = 'IPv4'
        }

        # 2. Domain Promotion
        ActiveDirectoryDsc\ADDomain CreateForest {
            DomainName                    = $Node.DomainName
            DomainNetbiosName             = $Node.DomainNetBIOSName
            SafeModeAdministratorPassword = $ConfigurationData.NonNodeData.SafeModePassword
            DomainAdministratorCredential = $ConfigurationData.NonNodeData.AdminCreds
            ForestMode                    = $Node.ForestMode
            DomainMode                    = $Node.DomainMode
            DependsOn                     = "[IPAddress]InternalIP"
        }

        # 3. Build OU Hierarchy
        foreach ($OU in $Node.OrganizationalUnits) {
            ActiveDirectoryDsc\ADOrganizationalUnit "OU_$($OU.Key)" {
                Name       = $OU.Name
                Path       = if ($OU.ParentPath -eq '') { $Node.DomainDN } else { "$($OU.ParentPath),$($Node.DomainDN)" }
                Protected  = $OU.Protected
                Description = $OU.Description
                DependsOn  = "[ADDomain]CreateForest"
            }
        }

        # 4. Security Groups (AGDLP)
        foreach ($Group in $Node.SecurityGroups) {
            ActiveDirectoryDsc\ADGroup "Group_$($Group.Key)" {
                GroupName  = $Group.GroupName
                GroupScope = $Group.GroupScope
                Category   = $Group.Category
                Path       = "OU=Groups,OU=BarmBuzz,$($Node.DomainDN)"
                DependsOn  = "[ADOrganizationalUnit]OU_Groups"
            }
        }

        # 5. Active Directory Users & Memberships
        foreach ($User in $Node.ADUsers) {
            ActiveDirectoryDsc\ADUser "User_$($User.Key)" {
                UserName              = $User.UserName
                GivenName             = $User.GivenName
                Surname               = $User.Surname
                DisplayName           = $User.DisplayName
                UserPrincipalName     = $User.UserPrincipalName
                Path                  = "$($User.OUPath),$($Node.DomainDN)"
                Password              = $ConfigurationData.NonNodeData.UserPassword
                DependsOn             = "[ADOrganizationalUnit]OU_$($User.DependsOnOUKey)"
            }

            # Add User to their defined Groups
            foreach ($GroupName in $User.GroupMembership) {
                ActiveDirectoryDsc\ADGroupMember "Add_$($User.Key)_to_$($GroupName)" {
                    GroupName   = $GroupName
                    Members     = $User.UserName
                    DependsOn   = "[ADUser]User_$($User.Key)"
                }
            }
        }

        # 6. Group Policy Objects
        foreach ($GPO in $Node.GroupPolicies) {
            ActiveDirectoryDsc\ADGpo "GPO_$($GPO.Key)" {
                DisplayName = $GPO.Name
                DomainName  = $Node.DomainName
                DependsOn   = "[ADDomain]CreateForest"
            }
        }

        # 7. GPO Registry Values (The Hardening Settings)
        foreach ($Reg in $Node.GPORegistryValues) {
            ActiveDirectoryDsc\ADGpoRegistryValue "Reg_$($Reg.Key)" {
                GpoName    = $Reg.GPOName
                Key        = $Reg.RegistryKey
                ValueName  = $Reg.ValueName
                ValueType  = $Reg.ValueType
                ValueData  = $Reg.ValueData
                DependsOn  = "[ADGpo]GPO_$($Reg.DependsOnGPO)"
            }
        }

        # 8. THE MISSING LINK: GPO OU Links
        foreach ($Link in $Node.GPOLinks) {
            ActiveDirectoryDsc\ADGpoLink "Link_$($Link.Key)" {
                GpoName      = $Link.GPOName
                TargetDN     = "$($Link.TargetOUPath),$($Node.DomainDN)"
                Order        = $Link.Order
                Enforced     = $Link.Enforced
                Enabled      = $Link.LinkEnabled
                DependsOn    = @("[ADGpo]GPO_$($Link.DependsOnGPO)", "[ADOrganizationalUnit]OU_$($Link.DependsOnOUKey)")
            }
        }
    }
}

# --- Execution Block (Student Lab Settings) ---
$ConfigData = @{
    AllNodes = $AllNodes # This injects your provided hash table
    NonNodeData = @{
        AdminCreds       = [PSCredential]::new("Administrator", (ConvertTo-SecureString "StudentPass123!" -AsPlainText -Force))
        SafeModePassword = (ConvertTo-SecureString "RecoveryPass123!" -AsPlainText -Force)
        UserPassword     = (ConvertTo-SecureString "BarmBuzz2026!" -AsPlainText -Force)
    }
}

BarmBuzz_Final_Build -ConfigurationData $ConfigData
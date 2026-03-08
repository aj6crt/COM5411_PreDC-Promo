Configuration StudentBaseline {
    param(
        [PSCredential]$DomainAdminCredential,
        [PSCredential]$DsrmCredential,
        [PSCredential]$UserCredential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration, ActiveDirectoryDsc, NetworkingDsc

    Node $AllNodes.NodeName {
        # 1. Promote Domain [cite: 266]
        WindowsFeature ADDS { Name = 'AD-Domain-Services'; Ensure = 'Present' }
        ADDomain BarmBuzzDomain {
            DomainName = $Node.DomainName; DomainNetbiosName = $Node.DomainNetBIOSName;
            Credential = $DomainAdminCredential; SafeModeAdministratorPassword = $DsrmCredential;
            DependsOn = '[WindowsFeature]ADDS'
        }
        WaitForADDomain Wait { DomainName = $Node.DomainName; Credential = $DomainAdminCredential; DependsOn = '[ADDomain]BarmBuzzDomain' }

        # 2. AD Sites and Subnets [cite: 204]
        foreach ($site in $Node.ADSites) {
            ADSite "Site_$($site.Name)" { Name = $site.Name; Ensure = 'Present'; Credential = $DomainAdminCredential; DependsOn = '[WaitForADDomain]Wait' }
        }
        foreach ($sub in $Node.ADSubnets) {
            ADSubnet "Subnet_$($sub.Name -replace '/','_')" { Name = $sub.Name; Site = $sub.Site; Ensure = 'Present'; Credential = $DomainAdminCredential; DependsOn = "[ADSite]Site_$($sub.Site)" }
        }

        # 3. Domain Password Policy
        ADDomainDefaultPasswordPolicy SetPasswordPolicy {
            DomainName                  = $Node.DomainName
            ComplexityEnabled           = $Node.PasswordPolicy.ComplexityEnabled
            MinPasswordLength           = $Node.PasswordPolicy.MinPasswordLength
            PasswordHistoryCount        = $Node.PasswordPolicy.PasswordHistoryCount
            MaxPasswordAge              = $Node.PasswordPolicy.MaxPasswordAge
            MinPasswordAge              = $Node.PasswordPolicy.MinPasswordAge
            LockoutThreshold            = $Node.PasswordPolicy.LockoutThreshold
            LockoutDuration             = $Node.PasswordPolicy.LockoutDuration
            LockoutObservationWindow    = $Node.PasswordPolicy.LockoutObservationWindow
            ReversibleEncryptionEnabled = $Node.PasswordPolicy.ReversibleEncryptionEnabled
            Credential                  = $DomainAdminCredential
            DependsOn                   = '[WaitForADDomain]Wait'
        }

        # 4. Organizational Units [cite: 266]
        foreach ($ou in $Node.OrganizationalUnits) {
            $path = if ($ou.ParentPath) { "$($ou.ParentPath), $($Node.DomainDN)" } else { $Node.DomainDN }
            ADOrganizationalUnit "OU_$($ou.Key)" {
                Name = $ou.Name; Path = $path; ProtectedFromAccidentalDeletion = $ou.Protected; Ensure = 'Present'; Credential = $DomainAdminCredential;
                DependsOn = if ($ou.DependsOnKey) { "[ADOrganizationalUnit]OU_$($ou.DependsOnKey)" } else { "[WaitForADDomain]Wait" }
            }
        }

        # 5. Security Groups [cite: 266]
        foreach ($grp in $Node.SecurityGroups) {
            ADGroup "Group_$($grp.Key)" {
                GroupName = $grp.GroupName; GroupScope = $grp.GroupScope; Category = $grp.Category;
                Path = "$($grp.OUPath), $($Node.DomainDN)"; Ensure = 'Present'; Credential = $DomainAdminCredential;
                DependsOn = "[ADOrganizationalUnit]OU_$($grp.DependsOnOUKey)"
            }
        }

        # 6. Users & Membership (Idempotent Script Resource)
        foreach ($user in $Node.ADUsers) {
            ADUser "User_$($user.Key)" {
                UserName = $user.UserName; Path = "$($user.OUPath), $($Node.DomainDN)"; Password = $UserCredential;
                Enabled = $true; Ensure = 'Present'; Credential = $DomainAdminCredential;
                DependsOn = "[ADOrganizationalUnit]OU_$($user.DependsOnOUKey)"
            }

            foreach ($groupName in $user.GroupMembership) {
                $grpEntry = $Node.SecurityGroups | Where-Object { $_.GroupName -eq $groupName }
                $uName = $user.UserName; $gName = $groupName
                Script "Add_$($user.Key)_to_$($gName)" {
                    GetScript = { return @{ Result = 'N/A' } }
                    TestScript = { (Get-ADGroupMember -Identity $using:gName).SamAccountName -contains $using:uName }
                    SetScript = { Add-ADGroupMember -Identity $using:gName -Members $using:uName }
                    DependsOn = @("[ADUser]User_$($user.Key)", "[ADGroup]Group_$($grpEntry.Key)")
                }
            }
        }

        # 7. Permission Delegations
        foreach ($deleg in $Node.Delegations) {
            ADObjectPermissionEntry $deleg.Key {
                Path = "$($deleg.TargetOUPath), $($Node.DomainDN)"; IdentityReference = "$($Node.DomainNetBIOSName)\$($deleg.IdentityGroupName)";
                ActiveDirectoryRights = $deleg.Rights; AccessControlType = $deleg.AccessControlType;
                ObjectType = $deleg.ObjectTypeGuid; ActiveDirectorySecurityInheritance = $deleg.InheritanceType;
                InheritedObjectType = $deleg.InheritedObjectType; Ensure = 'Present';
                DependsOn = @("[ADGroup]Group_$($deleg.DependsOnGroupKey)", "[ADOrganizationalUnit]OU_$($deleg.DependsOnOUKey)")
            }
        }
    }
}
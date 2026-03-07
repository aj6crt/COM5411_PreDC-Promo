# Runbook (Student)

step 1:  
Install vscode on Windows 11 and windows server 2025
Install git on Windows 11 and windows server 2025
Install powershell 7 on Windows 11 and windows server 2025

Intialise GPG Encryption Key on Windows 11
Set passphrase to sign each commit
Add GPG Encryption Key to Github

install 


Phase 1: Environment Preparation
Before executing the build script, these manual prerequisites must be met to avoid the "silent blockers" that prevent system restarts.

Set Local Administrator Password: Windows prohibits AD promotion on accounts with blank passwords.

Action: Open PowerShell as Admin and run: net user Administrator superw1n_user.

Verify Network Adapters: Ensure your virtual machine's network interface names match your configuration data.

Standard Names: Internal-Static and NAT.

Refactor Validation Tests: Prevent the Win32Exception crash in the post-build phase.

Action: In ADDS_Promotion.Tests.ps1 at line 107, replace Get-WmiObject with Get-CimInstance.

Phase 2: Configuration Integrity Check
Ensure StudentConfig.ps1 is syntactically correct to allow successful compilation into a .mof file.

Variable Scope: Use $Node.PropertyName inside the Node block to ensure specific data retrieval for the local machine.

Resource Naming: Use the resource name TimeZone instead of the cmdlet Get-TimeZone.

Module Imports: Use simplified imports (e.g., Import-DscResource -ModuleName NetworkingDsc) to avoid path ambiguity errors between PowerShell 5.1 and 7.

Phase 3: Execution and Promotion
This phase triggers the automated build and the subsequent server restart.

Execute Build: Run .\Run_BuildMain.ps1 from the project root.

Monitor Compilation: Ensure "Phase 2" reports [+] Compilation complete.

Promotion Trigger: The ADDomain resource will begin the forest creation.

Dependency: This resource will wait for InternalDNS and ADDS features to be present.

Automatic Restart: Once the promotion is finished, the LCM (Local Configuration Manager) will initiate a mandatory system reboot to finalize the Domain Controller role.

Phase 4: Post-Promotion Validation
After the reboot, the system will automatically run Pester tests to verify the build.

Domain Health: Confirm the BarmBuzz domain is reachable.

NIC Registration: Verify that the NAT interface has successfully disabled DNS registration via the DnsClient resource.
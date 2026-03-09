AI USAGE LOG: TECHNICAL PROBLEM RESOLUTION
Project: StudentConfig Build & Validation
-------------------------------------------------------------------------------

1. Syntax Error: Unexpected token '$Node'
Problem: The build crashed at line 73 of StudentConfig.ps1 with a ParserError.
AI Solution: Identified that metadata flags like Expect_NAT_Dhcp were incorrectly placed inside a DSC resource block.
Action: Deleted the problematic lines to fix the parser error and allow compilation.
2. Validation Failure: NAT NIC Static IP
Problem: Pester reported: "Expected 'Dhcp', but got WellKnown" on the NAT interface.
AI Solution: Explained that NAT adapters in Hyper-V labs must remain on DHCP to communicate with the host.
Action: Removed the NetIPAddress resource for the NAT interface from the configuration.
3. Pester Runtime: InternalNIC Retrieval
Problem: The test harness was unable to retrieve $script:InternalNIC.
AI Solution: Clarified that the Pester tests require the NodeName in AllNodes.psd1 to be exactly 'localhost'.
Action: Updated the NodeName to lowercase 'localhost' to successfully bind test variables.
4. Validation Crash: Win32Exception
Problem: The AD Promotion validation crashed at line 253 of the test script.
AI Solution: Identified that Get-WmiObject is deprecated and causes exceptions in PowerShell 7.5.4.
Action: Refactored the test code to use the modern Get-CimInstance cmdlet.
5. Promotion Blocker: Silent Failure
Problem: The configuration applied, but the machine refused to restart for domain promotion.
AI Solution: Noted that Windows Server blocks DC promotion if the local Administrator password is blank.
Action: Ran the terminal command "net user Administrator superw1n_user" to authorize the promotion.
6. Import Conflicts: Module Ambiguity
Problem: Ambiguous module errors were appearing in the build logs.
AI Solution: Suggested using simplified, explicit Import-DscResource statements for each required module.
Action: Cleaned up the imports at the top of StudentConfig.ps1 to resolve versioning conflicts.
7. Data Binding: Variable Scope Error
Problem: Properties were returning array objects instead of the required strings.
AI Solution: Explained the scope difference between the $AllNodes collection and the singular $Node reference.
Action: Updated all resource property lookups to use the $Node scope within the configuration.

8. Resource Mismatch: TimeZone Baseline
Problem: Test #2 failed because the TimeZone was not applying to the system.
AI Solution: Identified the use of the Get-TimeZone cmdlet instead of the TimeZone DSC resource.
Action: Corrected the resource type in the baseline configuration section.

9. Connectivity Issue: DNS Self-Reference
Problem: Internal networking failed once the AD DS role was installed.
AI Solution: Advised that Domain Controllers must point to their own loopback address (127.0.0.1) for initial DNS.
Action: Set DNSServers_Internal to @('127.0.0.1') in the AllNodes.psd1 data file.

10. Registration Failure: NAT DNS Leaks
Problem: Pre-DC Readiness Test #5 failed because the NAT NIC was registering in AD DNS.
AI Solution: Recommended adding a DnsClient resource specifically to disable address registration on the NAT alias.
Action: Added a DnsClient block with RegisterThisConnectionsAddress = $false.

11. Function Definition: Command Not Found
Problem: Errors stated: "The term 'StudentBaseline' is not recognized".
AI Solution: Determined that a syntax error elsewhere in the file prevented the configuration function from loading.
Action: Fixed bracket nesting in the networking section to allow the function to be defined.

12. Ordering Conflict: Computer Name Idempotency
Problem: The build failed on the second run when attempting to rename the machine.
AI Solution: Explained that computer naming must be a dependency for all subsequent networking resources.
Action: Added DependsOn = '[Computer]SetComputerName' to the NetIPAddress resources.

13. Security Standard: Credential Handling
Problem: Uncertain how to pass AD credentials without hardcoding them in the script.
AI Solution: Explained how to utilize [PSCredential] parameters within the Configuration block.
Action: Mapped $DsrmCredential and $DomainAdminCredential to the promotion resources.

14. Resource Sequence: Role vs. Promotion
Problem: Promotion errors occurred because the AD DS binaries were not yet ready.
AI Solution: Clarified the strict dependency required between WindowsFeature and ADDomain resources.
Action: Added a dependency on [WindowsFeature]ADDS in the domain forest creation block.

15. Service State: W32Time Failure
Problem: Baseline Test #6 reported the Windows Time service was not in a 'Running' state.
AI Solution: Suggested using the Service resource to force the state and set an automatic startup type.
Action: Implemented a Service WindowsTime block in the configuration.

16. Directory Management: Proof of Life
Problem: The Proof of Life test could not locate the required C:\TEST directory.
AI Solution: Explained the correct use of the File resource with Type = 'Directory' to ensure path existence.
Action: Added CreateTestDirectory and CreateTestFile resources to the baseline.

17. Path Resolution: Orchestration Failure
Problem: Run_BuildMain.ps1 was failing to find the configuration files.
AI Solution: Identified that the script requires execution relative to the repository root.
Action: Implemented $PSScriptRoot logic to ensure relative paths resolved correctly.

18. Functional Level: Invalid Forest Mode
Problem: Using 'Win2016' for the forest mode caused promotion errors on newer server versions.
AI Solution: Recommended using the string 'WinThreshold' for modern functional levels.
Action: Updated the AD settings in AllNodes.psd1 with the compatible string.

-------------------------------------------------------------------------------
END OF LOG
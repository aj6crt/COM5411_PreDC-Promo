Technical Design and Implementation Report: BarmBuzz Enterprise Active Directory Infrastructure
1. Executive Summary
The BarmBuzz Enterprise infrastructure represents a modern, automated approach to identity management and network security. Built upon the Windows Server 2019 platform, the environment is designed to support a multi-site retail operation (Bolton, Leeds, and Stoke) while maintaining a centralized "Single Source of Truth" through PowerShell Desired State Configuration (DSC). By implementing a Tiered Administrative Model and the AGDLP (Account, Global, Domain Local, Permissions) framework, BarmBuzz ensures that the "Principle of Least Privilege" is not merely a policy, but a technical reality. This report details the logical topology, security hardening, automated deployment workflows, and the troubleshooting lifecycle encountered during the pre-promotion and promotion phases of the BB-DC01 domain controller(Microsoft, 2023).

2. Logical Topology and Forest Architecture
2.1 The Forest Root (barmbuzz.local)
The heart of the enterprise is the barmbuzz.local forest. As the primary domain controller, BB-DC01 hosts the Global Catalog and holds all Flexible Single Master Operations (FSMO) roles. The choice of a .local non-routable suffix, while debated in some modern cloud contexts, was selected here to ensure a clean "split-brain" DNS environment where internal resources remain entirely shielded from public internet resolution.
2.2 Hierarchical Organizational Unit (OU) Design
To manage the geographical distribution of the BarmBuzz brand, a sophisticated OU hierarchy was engineered. Rather than a flat structure, the directory is split into:
Tier 0 (Control Plane): Reserved for Domain Controllers, high-privilege service accounts, and Domain Admin groups. This isolation ensures that even if a workstation in a retail branch is compromised, the attacker cannot easily traverse the directory to reach the forest root.
Regional OUs (Bolton, Leeds, Stoke): Each site acts as a logical container for its specific assets.
Asset-Type Sub-OUs: Within each region, objects are further bifurcated into Workstations and Users.
This physical manifestation of the administrative model ensures that Group Policy Objects (GPOs) can be targeted with surgical precision. For example, a "Screen Lock" policy can be applied to all Users regardless of location, while a "USB Block" policy is restricted specifically to the Workstations OU in the retail branches(Svidergol, n.d.).

3. Identity and Access Management (IAM)
3.1 The AGDLP Framework
BarmBuzz utilizes the industry-standard AGDLP model to manage permissions. This methodology abstracts the user from the resource, making the environment scalable.
A (Account): Individual users like ava.barista.
G (Global Group): Accounts are placed into role-based groups, such as GG_BB_Retail_Staff.
DL (Domain Local Group): These groups are assigned to specific resources, such as DL_FS_Recipes_Read.
P (Permissions): The actual Access Control List (ACL) on the folder or service.
3.2 Delegation of Control
One of the most significant security enhancements in this deployment is the delegation of rights to the GG_BB_IT_Helpdesk. By using the Active Directory Delegation Wizard (automated via DSC), helpdesk staff are granted the power to reset passwords and join machines to the domain within the Bolton OU only. This eliminates the need for helpdesk staff to be members of the "Domain Admins" group, adhering to the Principle of Least Privilege and significantly reducing the risk of "Pass-the-Hash" attacks.

4. Security Hardening and Risk Mitigation
4.1 The Identity Perimeter
Security at BarmBuzz begins at the login screen. A Fine-Grained Password Policy (FGPP) has been implemented to move beyond the default domain policy. While standard users follow a 10-character minimum, administrative accounts are subjected to even more stringent complexity requirements. To combat brute-force attacks, a strict lockout threshold is enforced: after five failed attempts, an account is locked for 30 minutes, requiring a manual review or a cooling-off period.
4.2 Workstation Lockdown: The POS Environment
The BarmBuzz retail environment relies on Point-of-Sale (POS) terminals. These are identified as high-risk assets. Through a dedicated GPO, these machines are subjected to an "Enforced Lockdown" state:
Mass Storage Block: A registry-level modification disables the usbstor service, preventing the use of thumb drives. This mitigates both data exfiltration (stealing customer data) and malware entry.
Legal Banner: All systems display a mandatory corporate warning. Under various data protection regulations, this provides the legal basis for monitoring and ensures users acknowledge the Acceptable Use Policy (AUP).
4.3 Network-Layer Security
To prevent Active Directory metadata from leaking, the PowerShell DSC configuration targets the network adapters. Specifically, on the NAT-facing (external) adapter, DNS registration is disabled. This ensures that the internal IP addresses and hostnames of the domain controller are not broadcast to the external network gateway, effectively hiding the internal topology from external reconnaissance(Gemini, 2025).

5. Automated Deployment via PowerShell DSC
5.1 Infrastructure as Code (IaC)
The BarmBuzz environment was not built manually; it was "declared." Using PowerShell Desired State Configuration (DSC), the team moved away from "click-next" administration to a repeatable code-based workflow. This ensures that if a second Domain Controller (BB-DC02) were needed, it could be deployed in minutes with 100% configuration parity.
5.2 The Logic vs. Data Planes
The DSC configuration is split to improve maintainability:
The Data Plane (Configuration Data): Contains the "what"—IP addresses, OU names (Bolton, Leeds, Stoke), and specific registry keys for hardening (e.g., disabling SMBv1 to prevent Ransomware like WannaCry).
The Logic Plane (The Script): Contains the "how"—the commands that check if a feature is installed and, if not, bring it to the desired state.
5.3 Post-OS Baseline and Promotion
The automation handles the entire lifecycle:
OS Hardening: Disabling legacy protocols (LM Hashes, SMBv1).
Feature Installation: Adding AD-Domain-Services and DNS roles.
Forest Initialization: Promoting the machine to a Domain Controller and setting the Directory Services Restore Mode (DSRM) password.
Object Provisioning: Creating the 13 core OUs, including the protection against accidental deletion.

6. Technical Challenges and Resolution (The Troubleshooting Lifecycle)
No enterprise deployment is without hurdles. The BarmBuzz project faced several "Blockers" that required deep-dive technical analysis(White, 2019).
6.1 Module Incompatibilities
Early in the deployment, the NetworkingDsc module failed to compile. Investigation revealed missing schema MOF files in the local environment. This was resolved by forcing a specific version of the module and ensuring the PowerShell Gallery was trusted, highlighting the importance of version pinning in DevOps workflows(sdwheeler, 2022).
6.2 The "Accidental Deletion" Paradox
During a phase where the OU structure needed to be reorganized, administrators found they could not delete the OUs even with Domain Admin rights. This was a result of the DSC script successfully applying the ProtectedFromAccidentalDeletion attribute. To resolve this, the nTSecurityDescriptor attribute had to be manually toggled via AD Administrative Center before the DSC script could be updated with the new structure.
6.3 Pester Testing Failures
The project utilized Pester, a testing framework for PowerShell. Initial "Integration Tests" failed because the tests were executing before the Domain Controller had finished its "Initial Replication" and DNS registration. The solution was the implementation of a "Wait-for-AD" logic loop within the testing script, ensuring the environment was fully "up" before being validated(SynEdgy, 2026).

7. Conclusion and Production Readiness
The BarmBuzz Enterprise infrastructure stands as a robust, secure, and highly organized environment. By integrating automated deployment (DSC) with a rigid security framework (AGDLP and Tiered Administration), the organization has minimized its attack surface while maximizing operational efficiency. The Bolton, Leeds, and Stoke sites are now logically isolated yet centrally managed, providing the perfect balance of regional autonomy and corporate oversight. As evidenced by the successful Pester validation and the enforcement of GPO-driven hardening, the BB-DC01 domain controller is fully prepared for production workloads.

Reference 

Microsoft (2023). Implementing Least-Privilege Administrative Models. [online] learn.microsoft.com. Available at: https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/security-best-practices/implementing-least-privilege-administrative-models.

Svidergol, B. (n.d.). What is Active Directory? [online] Available at: https://www.emtdist.com/wp-content/uploads/2022/04/What_is_Active_Directory.pdf.

Gemini. (2025). Gemini. [online] Available at: https://gemini.google.com/app/c845e04d8a1a08d2?utm_source=app_launcher&utm_medium=owned&utm_campaign=base_all [Accessed 3 Mar. 2026].

White, M. (2019). Active Directory security best practices for 2025. [online] Specops Software. Available at: https://specopssoft.com/blog/active-directory-security-best-practices/.

sdwheeler (2022). DSC Resources - PowerShell. [online] Microsoft.com. Available at: https://learn.microsoft.com/en-us/powershell/dsc/resources/resources?view=dsc-1.1.

SynEdgy. (2026). Mastering the DSC release pipeline. [online] Available at: https://synedgy.com/our-training-courses/mastering-dsc-release-pipeline/ [Accessed 4 Mar. 2026].


‌Ai Declaration: I have used AI to summarise my ai chats










# Design Notes (Student)

Explain your decisions:
- OU structure rationale
- Group model rationale
- GPO linking choices (later)
- Any security controls you applied



Design Notes: BarmBuzz Infrastructure Deployment
To support the BarmBuzz forest deployment, the infrastructure was designed with a focus on network isolation, secure promotion prerequisites, and automated resource management. The following decisions were implemented to ensure a stable and secure Domain Controller environment:

Network Isolation & Registration: A dual-NIC strategy was employed to separate internal domain traffic from external NAT traffic. The Internal-Static adapter is configured as the primary path for AD services, while the NAT interface is strictly managed via the DnsClient resource to disable dynamic registration, preventing internal IP leakage to external DNS.

Security & Promotion Prerequisites: To meet Active Directory’s strict security standards, a manual override of the local Administrator password was enforced prior to the build. This ensures the ADDomain resource can successfully promote the server without being blocked by credential security policies.

Resource Dependency Mapping: The DSC configuration utilizes a "bottom-up" dependency chain where core networking (IP and DNS) is verified before the AD-Domain-Services role is applied. This prevents the "orphan" resource errors previously encountered and ensures that the server is ready for a clean reboot immediately following a successful forest creation.

Automated Validation Refactoring: To ensure the environment remains healthy post-reboot, legacy Pester validation tests were refactored from Get-WmiObject to Get-CimInstance. This aligns with PowerShell 7 standards and prevents validation crashes during the final system health checks.
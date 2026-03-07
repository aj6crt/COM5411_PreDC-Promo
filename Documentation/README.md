# Documentation

Use these files for your written artefacts:
- Runbook.md: what you did, week by week
- DesignNotes.md: why you designed it this way
######
Internet-NAT (Ethernet0): This provides the server with internet connectivity for downloading Windows updates and installing roles.

#Internal-Static (Ethernet1): This is the private "lab" network where your Active Directory and other VMs will live.
######


### README: AD Automation IaC Environment ###

#### Overview ####

This repository contains the Infrastructure-as-Code (IaC) configurations and testing suite for automating an Active Directory (AD) environment. 

#### Core Technology Stack ####

Engine: Microsoft Desired State Configuration (DSC) v3 (dsc.exe).

Orchestration: PowerShell 7.1+ (Core).

Legacy Support: Windows PowerShell 5.1 (via DSC Compatibility Adapter).

Validation: Pester 5.7.1 testing framework.

Version Control: Git with GPG commit signing for identity verification.

Micrsoft Visual Code

##### Environment Design #####


 Infrastructure is defined in YAML/JSON files, which serve as the single source of truth.

The system checks current state vs. desired state; changes are only applied if "drift" is detected.

Dev Machine: Windows 11 with VS Code and RSAT tools.

Windows Server 2025 (Standard/Datacentre) with a Static IP.

##### Required Modules #####

The following modules must be installed in C:\Program Files\WindowsPowerShell\Modules to be accessible by both PowerShell engines:

ActiveDirectoryDsc (v6.6.0): For AD domain and object orchestration.

GroupPolicyDsc (v1.0.3): For declarative GPO management.

PSDesiredStateConfiguration: For common OS features (files, registry, etc.).

ComputerManagementDsc: For handling pending reboots.

### Workflow ###

Code: Author desired state in a YAML configuration file.

Deploy: Execute dsc config apply (on-demand) to enforce the state.

Commit: Stage and commit changes to Git using GPG signing.

Verify: Run Pester tests to validate that the physical infrastructure matches the code.

### Project Progress: Active Directory Domain Services (AD DS) Promotion Lab ###

Networking Strategy: Configured a dual-NIC environment consisting of an Internal-Static interface for domain traffic and a NAT interface for external connectivity.

Active Directory Setup: Defined the ADDomain resource to create a new forest with specified DomainName and DomainNetBIOSName

Dependency Mapping: Implemented DependsOn logic to ensure networking is stable (IP and DNS) before the Active Directory role is installed or promoted.

### ### Troubleshooting & Applied Fixes ###

During the build process, several "Build Killer" issues were identified and resolved:

1. DSC Compilation & Module Resolution

# The Issue: 
The compiler (PowerShell 5.1) failed to find modules like ComputerManagementDsc and NetworkingDsc due to path ambiguity between PowerShell 7 and 5.1.

# The Fix:

Updated Import-DscResource to use version pinning (e.g., ModuleVersion = '9.1.0') or simplified imports to match the system path.

2. Structural Syntax (Brace Management)

# The Issue:

Misplaced or missing closing braces (}) at lines 44 and 61 caused "orphaned" resources and PositionalParameterNotFound errors.

# The Fix:

Nested all resources (Computer, TimeZone, IPAddress, DnsClient) strictly within the Node $AllNodes.NodeName { ... } block.

3. Active Directory Prerequisites

# The Issue:

The promotion phase failed because the local Administrator password was blank, which is forbidden for Domain Controllers.

# The Fix

Executed net user Administrator superw1n_user to secure the account before promotion.

### Current Status: Validation Phase

i have multiple errors that stopping me from promoting my server to Domian Controller.

1. NAT NIC 

2. AD DS promotion failed and has win32eXCEPTION

3. DNS is still not working






# FSMO-Wizard

**Purpose**

This PowerShell script is used to transfer FSMO (Flexible Single Master Operations) roles from one domain controller to another. It also includes an optional function to demote the old domain controller.

**Usage**

    1. Run the script from the domain controller you are transferring roles from.
    2. Enter the name of the server you would like to transfer the roles to when prompted.
    3. Confirm domain replication.
    4. Choose which FSMO roles to transfer.
    5. Optionally demote the old domain controller.
    6. Reboot the server to complete the process.
    
**Disclaimer**

This script should be used with caution and only by experienced system administrators who are familiar with the process of transferring FSMO roles and demoting domain controllers. Make sure to back up all necessary data before running this script.

# Functions

#### FSMO-Selector

This function prompts the user to select which FSMO roles to transfer.

#### YN-Menu

This function is used to create a Yes/No prompt for the user. It takes two strings as parameters to build the prompt.

#### Transfer-Roles

This function performs the actual transfer of FSMO roles using the Move-ADDirectoryServerOperationMasterRole cmdlet. The function takes two parameters: the role(s) to transfer and the name of the server to transfer the role(s) to.

#### Demote-DC

This function is used to demote the old domain controller. It first confirms that the user wants to demote the server, and then runs a test to check if there are any issues before proceeding with the demotion using the Test-ADDSDomainControllerUninstallation and Uninstall-ADDSDomainController cmdlets.

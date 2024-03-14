# This script will transfer FSMO roles and, optionally, demote the old
# Domain Controller

function FSMO-Selector {
     
    $all = New-Object System.Management.Automation.Host.ChoiceDescription '&All', 'Answer: All'
    $pdc = New-Object System.Management.Automation.Host.ChoiceDescription '&PDCEmulator', 'Answer: PDCEmulator'
    $rid = New-Object System.Management.Automation.Host.ChoiceDescription '&RIDMaster', 'Answer: RIDMaster'
    $inf = New-Object System.Management.Automation.Host.ChoiceDescription '&InfrastructureMaster', 'Answer: InfrastructureMaster'
    $scm = New-Object System.Management.Automation.Host.ChoiceDescription '&SchemaMaster', 'Answer: SchemaMaster'
    $dnm = New-Object System.Management.Automation.Host.ChoiceDescription '&DomainNamingMaster', 'Answer: DomainNamingMaster'
    $cancel = New-Object System.Management.Automation.Host.ChoiceDescription '&Cancel', 'Answer: Cancel'


    $options = [System.Management.Automation.Host.ChoiceDescription[]]($all, $pdc, $rid, $inf, $scm, $dnm,$cancel)
    $choice = $host.ui.PromptForChoice("FSMO Roles", "What FSMO Roles would you like to transfer?", $options, 0)

    switch ($choice) {
        0 {"all"; Break}
        1 { 0; Break}
        2 { 1; Break}
        3 { 2; Break}
        4 { 3; Break}
        5 { 4; Break}
        6 {"cancel"; Break}
    }

    return $choice

}
function Menu-Builder ($Title, $Question, [String[]]$Options) {   
    #This function allows you to create a menu with any number of options. 
    #It takes three arguments: the title of the menu, the question to ask the user, 
    #and an array of strings representing the menu options. 
    #The function returns the selected menu option as a string.
    $Options += "Exit"
    foreach ($option in $Options){           
        $convertedOption = New-Object System.Management.Automation.Host.ChoiceDescription "&$($option)"
        [System.Management.Automation.Host.ChoiceDescription[]]$menuOptions += [System.Management.Automation.Host.ChoiceDescription[]]($convertedOption)
    }
    $choice = $host.ui.PromptForChoice($Title, $Question, $menuOptions, 0)
    if ($Options[$choice] -eq "Exit"){
        Write-Host "Now exiting script, good bye"
        break
    }
    Return $Options[$choice]
}

function Transfer-Roles {

    param($Role, $Identity)

    if ($Role -eq 'all'){
         Move-ADDirectoryServerOperationMasterRole -Identity $Identity -OperationMasterRole 0,1,2,3,4
    }else {
         Move-ADDirectoryServerOperationMasterRole -Identity $Identity -OperationMasterRole $Role
    }


}

function Demote-DC {

    $remove = MenuBuilder -Title "Please Confirm" -Question "Do you wish to Demote the server you're currently working on as well?" -Options "Yes", "No"

    if($remove -eq "Yes"){
        Write-Host "Testing Demotion first, please fix any issues found before proceeding."
        Test-ADDSDomainControllerUninstallation -RemoveApplicationPartitions
        Read-Host "Testing complete, press ENTER to continue..."
        Uninstall-ADDSDomainController -RemoveApplicationPartitions -NoRebootOnCompletion -Confirm
        Uninstall-WindowsFeature AD-Domain-Services -IncludeManagementTools
    }else{
        Break
    }

}

# Main script block

do {
    Write-Host "This script will transfer the whatever FSMO roles you choose to the Server name provided. It's best to run this script from the DC you're transfering roles from. Proceed with caution."
    $serverName = Read-Host "Please enter the name of the server you would like to transfer roles to:  "
    Write-Host "Confirming Domain replication first..."
    repadmin /showrepl
    $confirm = Menu-Builder -Title "Please Confirm." -Question "Does replication look good? Are you sure you would like to proceed?" -Options "Yes", "No"

    if ($confirm -eq "Yes"){
        $choice = FSMO-Selector
        if ($choice -eq "cancel"){
          Break
        }else{
          Transfer-Roles -Role $choice -Identity $serverName
        }       
    }else{
        Break
    }

    if ($choice -eq "all"){
        Demote-DC
    }

    $end = Menu-Builder -Title "Please Confirm" -Question "Do you need to do anything else?" -Options "No", "Yes"

}until ($end -eq "No")

Suspend-BitLocker -MountPoint C: -RebootCount 2
Restart-Computer

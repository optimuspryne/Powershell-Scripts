function Create-OUs ($Path,$DC1,$DC2) {
    Import-Module AdmPwd.PS

    [String[]] $ouNames = "Computers - GPO","Users - GPO","Servers - GPO","Hyper-V"

    foreach ($ou in $ouNames) {
        if ($ou -match "Hyper-V") {
            New-ADOrganizationalUnit -Name $ou -Path "OU=Servers - GPO,$($Path)"
        }else {
            New-ADOrganizationalUnit -Name $ou -Path $Path
        } 
    }
    Update-AdmPwdADSchema

    foreach ($ou in $ouNames) {
        if ($ou -match "Computers - OU" -or $ou -match "Servers - OU") {
            Set-AdmPwdComputerSelfPermission -OrgUnit $ou
            Set-AdmPwdReadPasswordPermission -OrgUnit $ou -AllowedPrincipals $DC1\Administrator,$DC1\DTP
            Set-AdmPwdResetPasswordPermission -OrgUnit $ou -AllowedPrincipals $DC1\Administrator,$DC1\DTP
        }
    }

    Write-Host "Created Organizational Units"
}

function Create-Admin-Users ($Path,$DTPPwd,$RMMPwd){
    New-ADUser -Name DTP -SAMAccountName DTP -DisplayName DTP -GivenName DTP -UserPrincipalName "DTP@$DC1.$DC2"-AccountPassword (ConvertTo-SecureString $DTPPwd -AsPlainText -Force) -PasswordNeverExpires $True -Enabled $true -Path "CN=Users,$Path"
    New-ADUser -Name RMM -SAMAccountName RMM -DisplayName RMM -GivenName RMM -UserPrincipalName "RMM@$DC1.$DC2"-AccountPassword (ConvertTo-SecureString $RMMPwd -AsPlainText -Force) -PasswordNeverExpires $True -Enabled $true -Path "CN=Users,$Path"

    [String[]] $adminGroups = "Domain Admins","Administrators","Enterprise Admins","Group Policy Creator Owners","Schema Admins"

    foreach ($adminGroup in $adminGroups) {
        Add-ADGroupMember -Identity $adminGroup -Members DTP, RMM
    }
}

function Create-AD-Users ($NumOfUsers,$CommonPW,$DC1,$DC2) {
    $i = 1
    $path = "OU=Users - GPO,dc=$($DC1),dc=$($DC2)"

    While ($i -le $NumOfUsers){
        $workstationName = "WS0$($i)"
        if ($i -ge 10) {
            $workstationName = "WS$($i)"
        }
        New-ADUser -SamAccountName $workstationName -Name $workstationName -DisplayName $workstationName -GivenName $WorkstationName -UserPrincipalName "$workstationName@$DC1.$DC2" -LogonWorkstations $workstationName -Enabled $True -AccountPassword (ConvertTo-Securestring $($commonPW) -AsPlainText -force) -PasswordNeverExpires $True -Path $path
        $i++
    }
    Write-Host "Created $($numOfUsers) Active Directory Accounts"
}

function Import-GPOs ($DC1,$DC2) {
    $path = "$($PSScriptRoot)\GPOs"
    $WSFLocation = $path+"\ImportAllGPOs.wsf"
    $gpopath = $path+"\GPO"
    cscript.exe $WSFLocation $gpopath

    $listOfGPOs = Get-GPO -All

    foreach ($gpo in $listOfGPOs) {
        if ($gpo.DisplayName -match "Computers:"){
            New-GPLink -Name $gpo.DisplayName -Target "OU=Computers - GPO,DC=$DC1,DC=$DC2"
        }if ($gpo.DisplayName -match "Users:") {
            New-GPLink -Name $gpo.DisplayName -Target "OU=Users - GPO,DC=$DC1,DC=$DC2"
        }if ($gpo.DisplayName -match "Domain:"){
            New-GPLink -Name $gpo.DisplayName -Target "DC=$DC1,DC=$DC2"
        }
    }

    New-GPLink -Name "Computers: Edge Settings" -Target "OU=Servers - GPO,DC=$DC1,DC=$DC2"
    New-GPLink -Name "Computers: Local Administrator Password Solution (LAPS)" -Target "OU=Servers - GPO,DC=$DC1,DC=$DC2"
    New-GPLink -Name "Hyper-V: Security" -Target "OU=Hyper-V,OU=Servers - GPO,DC=$DC1,DC=$DC2"

    Write-Host "Successfully Imported GPOs"
}

function Copy-Netlogon-And-Folders ($SplashtopCode,$DC1,$DC2) {
    ((Get-Content -path "$PSScriptRoot\NETLOGON Files\Splashtop.bat" -Raw) -replace 'SITECODE',$splashtopCode) | Set-Content -Path "$PSScriptRoot\NETLOGON Files\Splashtop.bat"

    if ("$DC1.$DC2" -ne "OFFICE.local") {
        ((Get-Content -path "$PSScriptRoot\NETLOGON Files\Splashtop.bat" -Raw) -replace 'OFFICE.local',"$DC1.$DC2") | Set-Content -Path "$PSScriptRoot\NETLOGON Files\Splashtop.bat"
        ((Get-Content -path "$PSScriptRoot\NETLOGON Files\Dentrix.bat" -Raw) -replace 'OFFICE.local',"$DC1.$DC2") | Set-Content -Path "$PSScriptRoot\NETLOGON Files\Dentrix.bat"
        ((Get-Content -path "$PSScriptRoot\NETLOGON Files\DellBios.bat" -Raw) -replace 'OFFICE.local',"$DC1.$DC2") | Set-Content -Path "$PSScriptRoot\NETLOGON Files\DellBios.bat"
    }
    Copy-Item $PSScriptRoot\FOLDERS\* -Destination D:\ -Recurse
    Copy-Item "$($PSScriptRoot)\NETLOGON Files\*" -Destination "\\$DC1.$DC2\NETLOGON\"

    Write-Host "Succesfully Copied Folders and Netlogon Files"
}

function Create-DFS-Shares ($DomainName) {
    New-SMBShare –Name “Deploy$” –Path “D:\DEPLOY” –ReadAccess "Authenticated Users", "System"
    New-SMBShare –Name “Share” –Path “D:\SHARE” –FullAccess "Authenticated Users"
    New-SMBShare –Name “Users$” –Path “D:\USERS” –FullAccess "Authenticated Users"

    $usersACL = Get-Acl "D:\Users"
    $usersACL.SetAccessRuleProtection($true, $false)
    $usersACL | Set-Acl "D:\USERS"

    [String[]] $userNames = "Administrators","Domain Admins","SYSTEM","CREATOR OWNER","Authenticated Users"

    foreach ($userName in $userNames){
        $usersACL = Get-Acl "D:\Users"
        $shareACL = Get-Acl "D:\Share"
        if ($userName -eq "Authenticated Users"){
            $usersAR = New-Object System.Security.AccessControl.FileSystemAccessRule("Authenticated Users", "ReadAttributes,ReadExtendedAttributes,CreateDirectories,AppendData,ReadPermissions", "ContainerInherit,ObjectInherit", "None", "Allow")
            $usersACL.SetAccessRule($usersAR)
            Set-Acl "D:\USERS" $usersACL
            $shareAR = New-Object System.Security.AccessControl.FileSystemAccessRule("Authenticated Users", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
            $shareACL.SetAccessRule($shareAR)
            Set-Acl "D:\Share" $shareACL
        }else{
            $usersAR = New-Object System.Security.AccessControl.FileSystemAccessRule($userName, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
            $usersACL.SetAccessRule($usersAR)
            Set-Acl "D:\USERS" $usersACL
        }
    }

    New-DfsnRoot -TargetPath "\\$env:computername\SHARE" -Type 'DomainV2' -Path "\\$DomainName\SHARE"
    New-DfsnRoot -TargetPath "\\$env:computername\USERS$" -Type 'DomainV2' -Path "\\$DomainName\USERS$"
    New-DfsnRoot -TargetPath "\\$env:computername\DEPLOY$" -Type 'DomainV2' -Path "\\$DomainName\DEPLOY$"
}

Copy-Item -Path "$PSScriptRoot\FOLDERS\DEPLOY\LAPS\LAPS.x64.msi" -Destination "C:\LAPS.x64.msi"
Start-Process MsiExec.exe -ArgumentList "/i C:\LAPS.x64.msi ADDLOCAL=CSE,Management,Management.UI,Management.PS,Management.ADMX ALLUSERS=1 /qn /norestart" -Wait

$domainName = (Get-ADDomain -Current LocalComputer).Forest
$dc1,$dc2 = $domainName.Split(".")
$path = "DC=$($dc1),DC=$($dc2)"

$splashtopCode = Read-Host "What is your Splashtop Deploy Code "
$dtpPwd = Read-Host "Please enter the password for Domain Admin DTP " -AsSecureString
$rmmPwd = Read-Host "Please enter the password for Domain Admin RMM " -AsSecureString
$numOfUsers = Read-Host "How many users do you need created "
$commonPW = Read-Host "Please enter the domain user Password " -AsSecureString

Copy-Netlogon-And-Folders -SplashtopCode $splashtopCode -DC1 $dc1 -DC2 $dc2
Create-DFS-Shares -DomainName $domainName
Create-Admin-Users -Path $path -DTPPwd $dtpPwd -RMMPwd $rmmPwd
Create-OUs -DC1 $dc1 -DC2 $dc2 -Path $path
Create-AD-Users -DC1 $dc1 -DC2 $dc2 -NumOfUsers $numOfUsers -CommonPW $commonPW
Import-GPOs -DC1 $dc1 -DC2 $dc2

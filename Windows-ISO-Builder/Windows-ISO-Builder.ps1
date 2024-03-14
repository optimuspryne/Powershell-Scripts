function Check-Keypress ($sleepSeconds) {
    <#
    This function checks for a keypress within a specified time duration.
    
    Parameters:
        - $sleepSeconds: The number of seconds to wait for a keypress.
    
    Returns:
       - $interrupted: A Boolean indicating whether a key was pressed within the specified time.
    #>

    $timeout = New-TimeSpan -Seconds $sleepSeconds
    $stopWatch = [Diagnostics.Stopwatch]::StartNew()
    $interrupted = $false

    while ($stopWatch.Elapsed -lt $timeout) {
        if ($Host.UI.RawUI.KeyAvailable) {
            $keyPressed = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyUp, IncludeKeyDown")
                if ($keyPressed.KeyDown -eq "True") { 
                    $interrupted = $true
                    break          
                } 
        }
    }
        return $interrupted
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
        $i++
    }
   
    $choice = $host.ui.PromptForChoice($Title, $Question, $menuOptions, 0)

    if ($Options[$choice] -eq "Exit"){
        Write-Host "Now exiting script, good bye"
        break
    }
    Return $Options[$choice]
}

function Menu-Execution ($MenuSelection, [String[]]$Versions) {
    <#
    This function performs different actions based on the selected menu option and Windows versions.
    
    Parameters:
        - $MenuSelection: The selected menu option.
        - $Versions: An array of Windows versions.
    #>

    foreach ($version in $Versions) {

        if ($version -eq "Win10" -or $version -eq "Win11"){
            $driversPath = "$($global:RootDir)\$($global:OSOptions[0])\$($global:WorkingDirs[0])"
            $scriptsPath = "$($global:RootDir)\$($global:OSOptions[0])\$($global:WorkingDirs[1])"
            $filesPath = "$($global:RootDir)\$($global:OSOptions[0])\$($global:WorkingDirs[2])"
        }else {
            $driversPath = "$($global:RootDir)\$($global:OSOptions[1])\$($global:WorkingDirs[0])"
            $scriptsPath = "$($global:RootDir)\$($global:OSOptions[1])\$($global:WorkingDirs[1])"
            $filesPath = "$($global:RootDir)\$($global:OSOptions[1])\$($global:WorkingDirs[2])"
            
        }

        switch ($MenuSelection) {
            "Update Scripts"{
                Mount-WindowsImage -Path "$($global:RootDir)\$($global:RootDirs[1])" -ImagePath "$($global:RootDir)\$($global:RootDirs[0])\$($version)\Sources\Install.wim" -Index 1
                Add-Files-And-Scripts -Version $version -FilesPath $filesPath -ScriptsPath $scriptsPath
                Dismount-WindowsImage -Path "$($global:RootDir)\$($global:RootDirs[1])" -Save
                Make-ISO -Version $version
            }"Add Drivers" {
                
                [String[]]$options = "All", "Boot Drivers", "OS Drivers"
                $userChoice = Menu-Builder -Title "Please Choose." -Question "What drivers do you need loaded?" -Options $options
                switch ($userChoice){
                    "All"{
                        Add-Boot-Drivers -Version $version -DriversPath $driversPath
                        Add-WS-Drivers -Version $version -DriversPath $driversPath
                        Dismount-WindowsImage -Path "$($global:RootDir)\$($global:RootDirs[1])" -Save
                        Make-ISO -Version $version
                    }"Boot Drivers"{
                        Add-Boot-Drivers -Version $version -DriversPath $driversPath
                        Make-ISO -Version $version
                    }"OS Drivers"{
                        Add-WS-Drivers -Version $version -DriversPath $driversPath
                        Dismount-WindowsImage -Path "$($global:RootDir)\$($global:RootDirs[1])"-Save
                        Make-ISO -Version $version
                    }
                }
            }"Everything"{
                Copy-ISO -Version $version -RestartCount 0
                Convert-ESD -Version $version
                Add-Boot-Drivers -Version $version -DriversPath $driversPath
                Add-WS-Drivers -Version $version -DriversPath $driversPath
                Add-Files-And-Scripts -Version $version -FilesPath $filesPath -ScriptsPath $scriptsPath
                Dismount-WindowsImage -Path "$($global:RootDir)\$($global:RootDirs[1])" -Save
                Start-Sleep -Seconds 15
                Make-ISO -Version $version
            }"Install Updates" {
                Write-Host "This Function is a work in progress, check back later..." -ForegroundColor Black -BackgroundColor Green
            }
        }
    }

}
    
function Make-Directories {
        #This function creates the necessary directories for the script to operate.

        Write-Host "Making Directories..." -ForegroundColor Black -BackgroundColor Green
        foreach ($rdir in $global:RootDirs) {
            #Makes the following folders under C:\WinWork: "ISO", "Mount", "Desktop OS", "Server OS"
            New-Item -Path "$($global:RootDir)\$($rdir)" -ItemType Directory
        }

        foreach ($version in $global:WinVersions) {
            #Makes the following folders under C:\WinWork\ISO: "Win10", "Win11", "Server2019", "Server2022"
            New-Item -Path "$($global:RootDir)\$($global:RootDirs[0])\$($version)" -ItemType Directory
        }

        foreach ($dir in $global:WorkingDirs) {
            #Makes the following folders under C:\WinWork\Desktop OS & C:\WinWork\Server OS: "Drivers", "Files", "Scripts", "Updates"
            New-Item -Path "$($global:RootDir)\$($global:RootDirs[2])\$($dir)" -ItemType Directory
            New-Item -Path "$($global:RootDir)\$($global:RootDirs[3])\$($dir)" -ItemType Directory
        }

        #The following line of code make these folders under C:\Winwork\Desktop OS\Drivers: "Win10", "Win11" & C:\WinWork\ServerOS\Drivers: "Server2019", "Server2022"
        New-Item -Path "$($global:RootDir)\$($global:RootDirs[2])\$($global:WorkingDirs[0])\$($global:WinVersions[0])" -ItemType Directory
        New-Item -Path "$($global:RootDir)\$($global:RootDirs[2])\$($global:WorkingDirs[0])\$($global:WinVersions[1])" -ItemType Directory
        New-Item -Path "$($global:RootDir)\$($global:RootDirs[3])\$($global:WorkingDirs[0])\$($global:WinVersions[2])" -ItemType Directory
        New-Item -Path "$($global:RootDir)\$($global:RootDirs[3])\$($global:WorkingDirs[0])\$($global:WinVersions[3])" -ItemType Directory

        #Creates a "Boot" folder under C:\WinWork\Desktop OS\Drivers & C:\WinWork\Server OS\Drivers
        New-Item -Path "$($global:RootDir)\$($global:RootDirs[2])\$($global:WorkingDirs[0])\Boot" -ItemType Directory
        New-Item -Path "$($global:RootDir)\$($global:RootDirs[3])\$($global:WorkingDirs[0])\Boot" -ItemType Directory
}

function Copy-Everything ([String[]]$Versions){
         <#
        This function handles the copying of files, ISOs, and drivers for the specified Windows versions.
    
        Parameters:
            - $Versions: An array of Windows versions.
        #>

        [String[]]$prompts = "boot drivers", "scripts", "supplemental files"

        #Ask the user about making the working directories at C:\WinWork
        $directoryPrompt = Menu-Builder -Title "Please Confirm" -Question "Do you need to create the working directories on your C:\ Drive?" -Options "Yes", "No"

        #If user chooses yes, then the necessary directories will be created in C:\
        if ($directoryPrompt -eq "Yes") {
            Make-Directories
        }
            $isoPath = Read-Host "Where are/is your ISO(s)?"
            $isoFiles = Get-ChildItem -File $isoPath -Filter *.iso

            foreach ($isoFile in $isoFiles) {
                Copy-Item -Path "$($isoPath)\$($isoFile)" -Destination $global:RootDir
            }
            Rename-ISOs

            foreach ($version in $Versions) {

                switch ($version) {
                    "Win10"{
                        $osRootDirectory = "Desktop OS"
                    }"Win11"{
                        $osRootDirectory = "Desktop OS"
                    }"Server2019"{
                        $osRootDirectory = "Server OS"  
                    }"Server2022"{
                        $osRootDirectory = "Server OS"
                    }
                }
                
                $copyPath = Read-Host "Where are your $($version) drivers?"
                Copy-Item -Path $copyPath\* -Destination "$($global:RootDir)\$($osRootDirectory)\$($global:WorkingDirs[0])\$($version)\" -Recurse -ErrorAction SilentlyContinue 

            }
            
            foreach ($prompt in $prompts) { 
                    $copyPath = Read-Host "Where are your $($osRootDirectory) $($prompt)"

                    switch ($prompt) {
                        "boot drivers" {
                            Copy-Item -Path $copyPath\* -Destination "$($global:RootDir)\$($osRootDirectory)\Drivers\Boot\" -Recurse -ErrorAction SilentlyContinue
                        }"scripts"{
                            Copy-Item -Path $copyPath\* -Destination "$($global:RootDir)\$($osRootDirectory)\$($global:WorkingDirs[1])\" -Recurse -ErrorAction SilentlyContinue
                        }"supplemental files"{
                            Copy-Item -Path $copyPath\* -Destination "$($global:RootDir)\$($osRootDirectory)\$($global:WorkingDirs[2])\" -Recurse -ErrorAction SilentlyContinue
                        }
                    }
                }                  
}

function Rename-ISOs {
    #This function renames ISO files based on their Windows versions.

    [String[]] $patterns = "*Win*10*", "*Win*11*"

    foreach ($pattern in $patterns){

        $isoToRename = Get-ChildItem -Path "$($global:RootDir)\" | Where-Object {$_.Name -like $pattern}

        switch ($pattern) {
             "*Win*10*"{
                Rename-Item -Path "$($global:RootDir)\$($isoToRename.Name)" -NewName "Win10.iso" -ErrorAction SilentlyContinue  
            }"*Win*11*"{              
                Rename-Item -Path "$($global:RootDir)\$($isoToRename.Name)" -NewName "Win11.iso" -ErrorAction SilentlyContinue
            }
        }

    }
}

function Copy-ISO ($Version, $RestartCount) {
    # This function copies files from mounted ISOs to the corresponding directories.

    Write-Host "Script will now copy your $($Version) ISO Files" -ForegroundColor Black -BackgroundColor Green

    $isoImg = "$($global:RootDir)\$($Version).iso"

    if (Test-Path -Path $isoImg -PathType Leaf) {

        Remove-Item "$($global:RootDir)\$($global:RootDirs[0])\$Version\*" -Recurse -Force

        # Drive letter - use desired drive letter
        $driveLetter = "W:"

        # Mount the ISO, without having a drive letter auto-assigned
        $diskImg = Mount-DiskImage -ImagePath $isoImg -NoDriveLetter
 
        # Get mounted ISO volume
        $volInfo = $diskImg | Get-Volume

        # Mount volume with specified drive letter (requires Administrator access)
        mountvol $driveLetter $volInfo.UniqueId

        #Copy contents of ISO to specified directory.  Directory is determined by the contents of $Version
        xcopy /E /I W:\ "$($global:RootDir)\$($global:RootDirs[0])\$($Version)"

        # Unmount ISO
        DisMount-DiskImage -ImagePath $isoImg

    }elseif ($RestartCount > 1){
        Write-Host "Your ISO files still cannot be found under C:\WinWork" -ForegroundColor Black -BackgroundColor Green
        Write-Host "Please make sure your iso file exists and is named correctly." -ForegroundColor Black -BackgroundColor Green
        Write-Host "Press any key to try again. Script will auto-abort in 1 minute..." -ForegroundColor Black -BackgroundColor Green
        if (Check-Keypress -sleepSeconds 60){
            Copy-ISO -Version $Version -RestartCount 0
        }else {
            Break
        }
    }else{
        $RestartCount++
        Write-Host "Unable to find a file named $($Version).iso at C:\WinWork." -ForegroundColor Black -BackgroundColor Green
        Write-Host "Attempting to rename iso files..." -ForegroundColor Black -BackgroundColor Green
        Rename-ISOs
        Copy-ISO -Version $Version -RestartCount $RestartCount
    }

    Write-Host "$($Version) ISO Files Copied Successfully" -ForegroundColor Black -BackgroundColor Green
    Start-Sleep -Seconds 15
}

function Convert-ESD ($Version) {
    #This function converts an encrypted install.esd file to an install.wim file for the specified Windows version.

    Write-Host "Now converting your $($Version) ESD File to WIM" -ForegroundColor Black -BackgroundColor Green

    $index = 6

    if ($Version -eq "Server2022" -or $Version -eq "Server2019") {
        $index = 2
        Export-WindowsImage -SourceImagePath "$($global:RootDir)\$($global:RootDirs[0])\$($Version)\Sources\Install.wim" -SourceIndex $index -DestinationImagePath "$($global:RootDir)\$($global:RootDirs[0])\$($Version)\Sources\converted.wim" -CompressionType Max -CheckIntegrity
        Remove-Item -Force  "$($global:RootDir)\$($global:RootDirs[0])\$($Version)\sources\install.wim"
        Rename-Item -Path "$($global:RootDir)\$($global:RootDirs[0])\$($Version)\Sources\converted.wim" -NewName "install.wim"
    }else {
        Export-WindowsImage -SourceImagePath "$($global:RootDir)\$($global:RootDirs[0])\$($Version)\Sources\Install.esd" -SourceIndex $index -DestinationImagePath "$($global:RootDir)\$($global:RootDirs[0])\$($Version)\Sources\Install.wim" -CompressionType Max -CheckIntegrity
        Remove-Item -Force  "$($global:RootDir)\$($global:RootDirs[0])\$($Version)\sources\install.esd"
    }

    Write-Host "$($Version) ESD Converted to WIM Successfully" -ForegroundColor Black -BackgroundColor Green
    Start-Sleep -Seconds 15
}

function Add-Boot-Drivers ($Version, $DriversPath) {  
    #This function adds boot drivers to the Boot.wim and Install.wim files for the specified Windows version.

    Write-Host "Now adding boot drivers for $($Version)" -ForegroundColor Black -BackgroundColor Green

    #Add drivers to Index 1 of Boot.wim
    Mount-WindowsImage -Path "$($global:RootDir)\$($global:RootDirs[1])" -ImagePath "$($global:RootDir)\$($global:RootDirs[0])\$($Version)\Sources\Boot.wim" -Index 1
    Add-WindowsDriver -Path "$($global:RootDir)\$($global:RootDirs[1])" -Driver "$($DriversPath)\Boot" -Recurse
    Dismount-WindowsImage -Path "$($global:RootDir)\$($global:RootDirs[1])" -Save

    #Add drivers to Index 2 of Boot.wim
    Mount-WindowsImage -Path "$($global:RootDir)\$($global:RootDirs[1])" -ImagePath "$($global:RootDir)\$($global:RootDirs[0])\$($Version)\Sources\Boot.wim" -Index 2
    Add-WindowsDriver -Path "$($global:RootDir)\$($global:RootDirs[1])" -Driver "$($DriversPath)\Boot" -Recurse
    Dismount-WindowsImage -Path "$($global:RootDir)\$($global:RootDirs[1])" -Save

    Write-Host "Boot Driversfrom $($DriversPath) for $($Version) Added Successfully" -ForegroundColor Black -BackgroundColor Green
    Start-Sleep -Seconds 15
}

function Add-WS-Drivers ($Version, $DriversPath) {
    #This function adds Windows Setup drivers to the Install.wim file for the specified Windows version.

    Write-Host "Now Adding $($Version) Workstation Drivers to Install.WIM" -ForegroundColor Black -BackgroundColor Green

    Mount-WindowsImage -Path "$($global:RootDir)\$($global:RootDirs[1])" -ImagePath "$($global:RootDir)\$($global:RootDirs[0])\$($Version)\Sources\Install.wim" -Index 1
    Add-WindowsDriver -Path "$($global:RootDir)\$($global:RootDirs[1])" -Driver "$($DriversPath)\$($Version)" -Recurse

    Write-Host "Workstation Drivers from $($DriversPath) for $($Version) Added Successfully" -ForegroundColor Black -BackgroundColor Green
    Start-Sleep -Seconds 15
}

function Add-Files-And-Scripts ($Version, $FilesPath, $ScriptsPath) {
    #This function adds files and scripts to the appropriate directories for the specified Windows version.

    if (Test-Path -Path "$($global:RootDir)\$($global:RootDirs[1])\Windows\Panther") {
        Copy-Item -Path "$($FilesPath)\*unattend.xml" -Destination "$($global:RootDir)\$($global:RootDirs[1])\Windows\Panther\" -ErrorAction SilentlyContinue     
    }else {
        New-Item -Path "$($global:RootDir)\$($global:RootDirs[1])\Windows\Panther" -ItemType Directory
        Copy-Item -Path "$($FilesPath)\*unattend.xml" -Destination "$($global:RootDir)\$($global:RootDirs[1])\Windows\Panther\" -ErrorAction SilentlyContinue
    }

    Write-Host "Unattend File for $($Version) Copied from $($FilesPath) to $($global:RootDir)\$($global:RootDirs[1])\Windows\Panther" -ForegroundColor Black -BackgroundColor Green
        
    if (Test-Path -Path "$($global:RootDir)\$($global:RootDirs[1])\Windows\Setup\Scripts") {
        Copy-Item -Path "$($ScriptsPath)\*" -Destination "$($global:RootDir)\$($global:RootDirs[1])\Windows\Setup\Scripts\" -Recurse
    }else {
        Copy-Item -Path "$($ScriptsPath)\" -Destination "$($global:RootDir)\$($global:RootDirs[1])\Windows\Setup\Scripts" -Recurse
    }

    Write-Host "Scripts for $($Version) copied from $($ScriptsPath) to $($global:RootDir)\$($global:RootDirs[1])\Windows\Setup\Scripts" -ForegroundColor Black -BackgroundColor Green

    if (Test-Path -Path "$($global:RootDir)\$($global:RootDirs[1])\Windows\Setup\Files") {
        Copy-Item -Path "$($FilesPath)\*" -Destination "$($global:RootDir)\$($global:RootDirs[1])\Windows\Setup\Files\" -Recurse
    }else {
        Copy-Item -Path "$($FilesPath)\" -Destination "$($global:RootDir)\$($global:RootDirs[1])\Windows\Setup\Files" -Recurse
    }

    Write-Host "Files for $($Version) copied from $($FilesPath) to $($global:RootDir)\$($global:RootDirs[1])\Windows\Setup\Files" -ForegroundColor Black -BackgroundColor Green
    Start-Sleep -Seconds 15 
}

function Make-ISO ($Version) {
    #This function creates a bootable ISO file for the specified Windows version.

    Write-Host "Now Creating your Custom $($Version) ISO" -ForegroundColor Black -BackgroundColor Green

    $currentDate = Get-Date -Format MM-dd-yyyy

    #Creates bootable ISO from the files located in C:\WinWork\ISO\WinXX.
    CD "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\"
    ./oscdimg.exe -h -m -o -u2 -udfver102 -bootdata:2#p0,e,bC:\WinWork\ISO\$Version\boot\etfsboot.com#pEF,e,bC:\WinWork\ISO\$Version\efi\microsoft\boot\efisys.bin -lWindows C:\WinWork\ISO\$($Version) "C:\WinWork\$($Version) $($currentDate).iso"
    CD C:\
    Write-Host "Successfully created your custom $($Version) ISO at C:\WinWork\" -ForegroundColor Black -BackgroundColor Green
}

function Get-Started {

    #This is the main function of the script that initiates the ISO creation process.

    [String[]]$verMenu += Menu-Builder -Title "Please Answer." -Question "Which Windows version are you making an ISO for?" -Options $global:OSOptions

    Write-Host "`n*************************************************************************************************************" -ForegroundColor Black -BackgroundColor Green
    Write-Host "**                                                                                                         **" -ForegroundColor Black -BackgroundColor Green
    Write-Host "**   Before continuing make sure your vanilla ISOs are copied to C:\WinWork\                               **" -ForegroundColor Black -BackgroundColor Green
    Write-Host "**   Your ISOs should be named Server20XX.iso and WinXX.iso, the script will attempt to rename them.       **" -ForegroundColor Black -BackgroundColor Green
    Write-Host "**   Your Desktop OS installation drivers should be copied to C:\WinWork\Desktop OS\Drivers\{Win Version}  **" -ForegroundColor Black -BackgroundColor Green
    Write-Host "**   Your Desktop OS Boot or WinPE drivers should be copied to C:\WinWork\Desktop OS\Drivers\Boot\         **" -ForegroundColor Black -BackgroundColor Green
    Write-Host "**   Your Desktop OS scripts should be copied to C:\WinWork\Desktop OS\Scripts\                            **" -ForegroundColor Black -BackgroundColor Green
    Write-Host "**   Your Desktop OS supplemental files should be copied to C:\WinWork\Desktop OS\Files\                   **" -ForegroundColor Black -BackgroundColor Green
    Write-Host "**   Your Server OS installation drivers should be copied to C:\WinWork\Server OS\Drivers\{Win Version}    **" -ForegroundColor Black -BackgroundColor Green
    Write-Host "**   Your Server OS Boot or WinPE drivers should be copied to C:\WinWork\Server OS\Drivers\Boot\           **" -ForegroundColor Black -BackgroundColor Green
    Write-Host "**   Your Server OS scripts should be copied to C:\WinWork\Server OS\Scripts\                              **" -ForegroundColor Black -BackgroundColor Green
    Write-Host "**   Your Server OS supplemental files should be copied to C:\WinWork\Server OS\Files\                     **" -ForegroundColor Black -BackgroundColor Green
    Write-Host "**                                                                                                         **" -ForegroundColor Black -BackgroundColor Green
    Write-Host "*************************************************************************************************************`n" -ForegroundColor Black -BackgroundColor Green
    Write-Host "The script can also create the correct directories and copy your files to them if you provide the locations." -ForegroundColor Black -BackgroundColor Green

    switch ($verMenu) {
         "Desktop OS" {
            $verMenu[0] = $global:WinVersions[0]
            $verMenu += $global:WinVersions[1] 
         }
         "Server OS" {
            $verMenu[0] = $global:WinVersions[2]
            $verMenu += $global:WinVersions[3] 
         }
         "All" {
            $verMenu = $global:WinVersions
         }
    }
    
    $copyQuestion = Menu-Builder -Title "Please Confirm" -Question "Do you need all of your files, scripts, ISOs etc copied, or the working directories created?" -Options "No", "Yes"
    if ($copyQuestion -eq "Yes") {
       Copy-Everything -Versions $verMenu
    }

    $menuSelection = Menu-Builder -Title "Please Confirm" -Question "What do you need this script to do?" -Options $global:ScriptFunctions
    Menu-Execution -MenuSelection $menuSelection -Version $verMenu

    Write-Host "This script will abort in 1 minute." -ForegroundColor Black -BackgroundColor Green
    Write-Host "Press any key to start over...." -ForegroundColor Black -BackgroundColor Green

    if (Check-Keypress -sleepSeconds 60) {
        Get-Started
    }else {
        Break
    }

}

[String[]]$global:ScriptFunctions = "Update Scripts", "Everything", "Add Drivers", "Install Updates"
[String[]]$global:OSOptions = "Desktop OS", "Server OS", "All", "Custom"
[String[]]$global:WinVersions = "Win10", "Win11", "Server2019", "Server2022"
[String[]]$global:WorkingDirs = "Drivers", "Scripts", "Files", "Updates"
[String[]]$global:RootDirs = "ISO", "Mount", "Desktop OS", "Server OS"
$global:RootDir = "C:\WinWork"

Get-Started

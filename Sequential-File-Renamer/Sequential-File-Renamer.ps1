function Menu-Builder ($Title, $Question, [String[]]$Options) {   
    #This function allows you to create a menu with any number of options. 
    #It takes three arguments: the title of the menu, the question to ask the user, 
    #and an array of strings representing the menu options. 
    #The function returns the selected menu option as a string.

    #Creates loops through $Options to create a ChoiceDescription object based on string value in $Options
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

function Get-Info {
    #This function is for gathering the necessary info from the user and adding it a String array.  It then returns this array for later use
  
    [string]$directory = Read-Host -Prompt "Where are the files located?"
  
    #Making sure the directory provided exists and that the user actually entered text.  If neither then user is prompted to provide one again
    if ($directory -eq ""){              
        do {
            Write-Host "Entry cannot be empty please try again."
            [string]$directory = Read-Host -Prompt "Where are the files located?"
        }until ($directory -ne "")       
    }elseif (!(Test-Path -Path $directory)){
        do {
            Write-Host "The location provided does not exist..."
            [string]$directory = Read-Host -Prompt "Where are the files located?"
        }until (Test-Path -Path $directory)    
    }
    [string]$newName = Read-Host -Prompt "What's the new name?"
    #Making sure the name provided isn't blank.  If it is user is prompted to provide the name again
    if ($newName -eq ""){
         do {
            Write-Host "The Name cannont be blank..."
            [string]$newName = Read-Host -Prompt "What's the new name?"
        }until ($newName -ne "")    
    }

    [string]$incrementPatt = Menu-Builder -Title "Please Confirm" -Question "What do you want your incremental pattern to look like?" -Options $global:Patterns
    [String[]]$newInfo = $directory, $newName, $incrementPatt

    Return $newInfo
}

function Get-Files ([String[]]$NewInfo) {
        
    foreach ($format in $global:Formats) {
        [array]$sortedFiles += Get-ChildItem -File $NewInfo[0] -Filter "*.$($format)"
    }

    [array]$sortedFiles = [array]$sortedFiles | Sort-Object { [regex]::Replace($_.Name, '\d+', { $args[0].Value.PadLeft(20) }) }

    if ($sortedFiles.Count -eq 0){
        Write-Host "There are no files in the directory provided. Please confirm there are files in the folder and that you provided the correct file extension."
        $prompt = Menu-Builder -Title "Please Confirm" -Question "Do you want to start over?" -Options "Yes", "No"

        if ($prompt -eq "Yes") {
            Main
        }else{
            break
        }
    }
    Return $sortedFiles
}

function Get-Format ([string]$FileName) { 
    
    $lastChar = (($FileName.Length) - 1)
    $twoCharFormat = $lastChar - 2
    $threeCharFormat = $lastChar -3

    if ($FileName[$twoCharFormat] -contains "."){
        [string]$format = $FileName[($lastChar - 1),($lastChar)]
        [string]$format = $format -replace " ",""
    }elseif ($FileName[$threeCharFormat] -contains ".") {
        [string]$format = $FileName[($lastChar - 2),($lastChar - 1),($lastChar)]
        [string]$format = $format -replace " ",""
    }else {
        [string]$format = $FileName[($lastChar - 3),($lastChar - 2),($lastChar - 1),($lastChar)]
        [string]$format = $format -replace " ",""
    }
    
    return $format

}

function Rename-Files ([array]$SortedFiles, [String[]]$NewInfo) {
    
    $directory = $NewInfo[0]
    $newName = $NewInfo[1]
    $chosenIncrement = $NewInfo[2]
    [int]$counter = 1
    
    switch ($chosenIncrement) {
        "S01E01" {

            [int]$seasonNum = Read-Host "What's the Season number?"

            if ($seasonNum -ge 10){
                $season = "S$($seasonNum)"
            }else {
                $season = "S0$($seasonNum)"
            }
            foreach ($file in $SortedFiles) {

                $format = Get-Format -FileName $file
               
                if ($counter -le 9) {                             
                    Rename-Item -LiteralPath $directory\$file -NewName "$($newName) $($season)E0$($counter).$($format)"
                }else {           
                    Rename-Item -LiteralPath $directory\$file -NewName "$($newName) $($season)E$($counter).$($format)"
                }
                $counter++
            }
                 
        }"E01" {
            foreach ($file in $SortedFiles) {

                $format = Get-Format -FileName $file


                if ($counter -le 9) {
                    Rename-Item -LiteralPath $directory\$file -NewName "$($newName) E0$($counter).$($format)"
                }else {
                    Rename-Item -LiteralPath $directory\$file -NewName "$($newName) E$($counter).$($format)"
                }

                $counter++
            }

        }"01" {
            foreach ($file in $SortedFiles) {
                $format = Get-Format -FileName $file
                Rename-Item -LiteralPath $directory\$file -NewName "$($newName) 0$($counter).$($format)"
                $counter++
            }

        }"1" {
            foreach ($file in $SortedFiles) {
                $format = Get-Format -FileName $file
                Rename-Item -LiteralPath $directory\$file -NewName "$($newName) $($counter).$($format)"
                $counter++
            }

        }
    }
    
}

function Start-Up {
   
    [String[]]$newInfo = Get-Info
    [array]$userFiles = Get-Files -NewInfo $newInfo

    #Print a sorted list of your files to make sure everything is renamed in the right order
    foreach ($file in $userFiles) {
        Write-Host $file
    }

    #Confirmation of correct sorting is needed to proceed
    $sorted = Menu-Builder -Title "Please Confirm" -Question "Do the files appear sorted correctly?" -Options "Yes", "No"

    if ($sorted -eq "No") {        
        Write-Host "If the files aren't sorted correctly, either incorrect information has been entered or something is terribly wrong."
        $restart = Menu-Builder -Title "Please Confirm" -Question "Would you like to start over?" -Options "No","Yes"

        if ($restart -eq "Yes"){
            Main
        }else{
            break
        }        
    }else {
        #Proceed with renaming your files
        Rename-Files -SortedFiles $userFiles -NewInfo $newInfo
    }
}

[String[]]$global:Formats = "webm", "mkv", "flv", "vob", "ogv", "drc", "gif", "gifv", "mng", "avi", "MTS", "M2TS", "TS", "mov", "qt", "wmv", "yuv", "rm", "rmvb", "viv", "asf", "amv", "mp4", "m4p", "m4v", "mpg", "mp2", "mpeg", "mpe", "mpv", "m2v", "svi", "3gp", "3g2", "mxf", "roq", "nsv", "flv", "f4v", "f4p", "f4a", "f4b"         
[String[]]$global:Patterns = "S01E01", "E01", "01", "1" 

Start-Up

do {
    $end = Menu-Builder -Title "Please Confirm" -Question "Do you need to rename any other files?" -Options "Yes", "No"

    if ($end -eq "Yes") {
        Start-Up
    }else {
        Write-Host "Thanks and Bye Bye.."
        break
    } 
}until ($end -eq "No")

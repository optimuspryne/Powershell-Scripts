# Video File Batch Renaming Script

# Introduction

This PowerShell script is used to rename video files in a directory based on a specified naming convention. It works by allowing the user to choose the directory where the files are located, the new name for the files, and an incremental pattern to apply to each file. The script searches for known video file formats and only renames those files in the specified directory in ascending order based on the incremental pattern.

# Prerequisites

    Windows operating system
    PowerShell 5.1 or later

# Usage

    Open PowerShell, navigate to the directory where the script is located. Run the script by typing 
    .\Sequential-File-Renamer.ps1 and pressing Enter. Follow the prompts to choose the directory where the files 
    are located, the new name for the files, and the incremental pattern to apply to each file. The script will 
    rename the files based on the specified pattern.

# Functions

The script contains several functions that are used to accomplish the video file renaming task:

## Menu-Builder

This function creates a menu with any number of options. It takes three arguments: the title of the menu, the question to ask the user, and an array of strings representing the menu options. The function returns the selected menu option as a string.

## Get-Info

This function is used to gather the necessary information from the user and add it to a string array. It then returns this array for later use.

## Get-Files

This function gets all the files with known video file formats (.mkv, .avi, etc...)in the specified directory and returns an array of these files sorted in ascending order based on the incremental pattern.

## Get-Format

This function is used to extract the file format from the file name.

## Rename-Files

This function renames the video files based on the specified pattern.

# Conclusion

This PowerShell script provides an easy and efficient way to rename video files, and only video files, in a directory. With its user-friendly menu, it allows the user to select the directory, new name, and incremental pattern, making the file renaming process quick and hassle-free.

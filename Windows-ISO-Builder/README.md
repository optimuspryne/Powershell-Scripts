# Windows-ISO-Builder

This script automates the process of building Windows installation media from ISO files, including adding drivers and custom scripts, and creating a new ISO with the updated files.  Please note that this script is provided as-is, and is not guaranteed to work in all situations. Use at your own risk, and make sure to test any modifications thoroughly before deploying them in a production environment.

Getting Started

    Download the script and save it to your local machine.
    Open PowerShell as an administrator and navigate to the folder where you saved the script.
    Run the script using the following command: .\Windows-ISO-Builder.ps1

# Usage

When prompted, enter the location of your ISO files, supplemental files, boot drivers, additional drivers, and custom scripts.

Choose from one of the following options:

	Update Scripts: Mounts the Windows image, adds files and scripts, and creates a new ISO.

	Add Drivers: Prompts for what drivers you need loaded, then adds them to the image and creates a new ISO.

	Everything: Copies ISO files, converts ESD to WIM, adds boot and additional drivers, adds files and scripts, 
	and creates a new ISO.

	Install Updates: This function is a work in progress and will not work.

The new ISO file(s) will be created in the C:\WinWork directory.

# Requirements

    PowerShell 5.1 or later.
    Windows Assessment and Deployment Kit (ADK) for Windows 10, version 1809 or later.
    A Windows ISO file.
    
    
# Overview

This PowerShell script provides several functions for building and modifying Windows installation media. These functions can be used to create custom ISO images, add drivers and files to an existing image, and more.

The script contains the following functions.  To use these functions, simply call them by name and pass in the necessary parameters. Note that some functions may require additional setup or configuration before use:

#### Check-Keypress: 
This function checks if a key has been pressed within a specified time frame. It takes one argument: the number of seconds to wait for a keypress. If a key is pressed within the specified time frame, the function returns True; otherwise, it returns False.

#### Menu-Builder: 
This function allows you to create a menu with any number of options. It takes three arguments: the title of the menu, the question to ask the user, and an array of strings representing the menu options. The function returns the selected menu option as a string.

#### Menu-Execution: 
This function executes the selected menu option. It takes two arguments: the selected menu option as a string, and an array of strings representing the Windows versions to operate on. Depending on the selected menu option, this function calls other functions to perform the required tasks.

#### Make-Directories: 
This function creates the necessary directories for the script to operate. It creates a set of directories under the C:\WinWork directory for each Windows version specified.

#### Copy-ISO
This function copies the Windows ISO image to the appropriate directory. It takes one argument: the Windows version to operate on.

#### Copy-Everything:
This function copies the Windows ISO image, supplemental files, and drivers to the appropriate directories. It prompts the user to specify the location of the required files.

#### Add-Boot-Drivers: 
This function adds the specified boot drivers to the mounted Windows installation image.

#### Add-WS-Drivers: 
This function adds the specified Windows Server drivers to the mounted Windows installation image.

#### Add-Files-And-Scripts: 
This function adds the specified supplemental files and scripts to the mounted Windows installation image.

#### Convert-ESD: 
This function converts the Windows installation image to the .wim format.

#### Make-ISO: 
This function creates an ISO image from the modified Windows installation image.

# Conclusion
This PowerShell script automates the process of creating custom Windows installation media by providing a set of functions that perform various tasks. By using this script, you can save time and effort when creating Windows installation media, and ensure that your customizations are applied consistently across multiple installations.

##### EXPOSED FUNCTIONS #####
# Import config with all of our settings
$ConfigFileLocation = "YOUR PATH GOES HERE"
$configFile = ([xml](Get-Content $ConfigFileLocation))
$config = $configFile.Root

# Function to update log file
function updateLogs() {
param(
[parameter(mandatory=$true)][string]$Message,
[parameter(mandatory=$true)][string]$Level
)

    # First check if the log file for today exists
    $FilePath = ([string]::Format("{1}logs\{0}.txt",(Get-date -Format dd-MM-yy), $config.installRoot))
    $CheckFile = Test-Path -Path $FilePath

    # If not then create it and write to log file
    if ($CheckFile -eq $false) {

        New-Item -Path $FilePath -ItemType File | Out-Null
        # Write to log to state that we've created it
        writeToLog -Level "FATAL" -FullFilePath $FilePath -Message "Log file created"
    }

    # Then write to file
    writeToLog -Level $Level -FullFilePath $FilePath -Message $Message

}

# Function to attempt create of year folder
function createYearFolder() {
param(
[parameter(mandatory=$true)][string]$Year,
[parameter(mandatory=$true)][System.Management.Automation.PSCredential]$Creds
)
    
    # Encode check in a job to enable running as a different user
    $CheckFolderResults = createFolder -Route $Year -Creds $Creds


    # Then write to log file if we created the folder
    if ($CheckFolderResults -eq 1) {

        updateLogs -Message "$Year folder created" -Level "TRACE"

    }

}

# Function to attempt creation of Client Folder
function createClientFolder() {
param(
[parameter(mandatory=$true)][string]$ClientName,
[parameter(mandatory=$true)][string]$Year,
[parameter(mandatory=$true)][System.Management.Automation.PSCredential]$Creds
)

    # Get route
    $Route = $Year + "\" + $ClientName

    # Get results
    $CheckFolderResults = createFolder -Route $Route -Creds $Creds

    # Then write to log file if we created the folder
    if ($CheckFolderResults -eq 1) {

        updateLogs -Message "$Year \ $ClientName folder created" -Level "TRACE"

    }

}

# Function to attempt to creation of Day Folder
function createDayFolder() {
param(
[parameter(mandatory=$true)][string]$ClientName,
[parameter(mandatory=$true)][string]$Year,
[parameter(mandatory=$true)][string]$Day,
[parameter(mandatory=$true)][System.Management.Automation.PSCredential]$Creds
)


    # Get route
    $Route = $Year + "\" + $ClientName + "\" + $Day

    # Get results
    $CheckFolderResults = createFolder -Route $Route -Creds $Creds

    # Then write to log file if we created the folder
    if ($CheckFolderResults -eq 1) {

        updateLogs -Message "$Year \ $ClientName \ $Day folder created" -Level "TRACE"

    }


}

# function to move file
function moveReport() {
param(
[parameter(mandatory=$true)][string]$ClientName,
[parameter(mandatory=$true)][string]$Year,
[parameter(mandatory=$true)][string]$Day,
[parameter(mandatory=$true)][string]$NewFileName,
[parameter(mandatory=$True)][System.IO.FileInfo]$OriginalFile,
[parameter(mandatory=$true)][System.Management.Automation.PSCredential]$Creds
)

    try {
        
        # Try the rename
        $File | Rename-Item -NewName $NewFileName -ErrorAction Stop

    } catch [System.IO.IOException] {
        
        # Catch IO exception
        # Write to logs
        updateLogs -Message ("Error while trying to move " + ([string]::Format("{0}\$NewFileName",$OriginalFile.DirectoryName)) + " :" + $Error[0].Exception) -Level "ERROR"
        # Attempt a second rename
        try {

            $NewFileName = $NewFileName.Replace($OriginalFile.Extension.ToString(),[string]::Format("-{0}{1}",(get-date).TimeOfDay.ToString().Replace(".","").Substring(0,8).Replace(":","-"),$OriginalFile.Extension))
            $File | Rename-Item -NewName $NewFileName -ErrorAction Stop

        } catch {

            updateLogs -Message ("Second rename failed: " + $Error[0].Exception + " aborting move") -Level "ERROR"

        }


    } catch { # Catch unexpected exception

        updateLogs -Message ("Error while trying to move " + ([string]::Format("{0}\$NewFileName",$OriginalFile.DirectoryName)) + " :" + $Error[0].Exception) -Level "ERROR"
    }
    
    # Work out destination
    New-PSDrive -Name $config.tempDriveLetter -PSProvider FileSystem -Root $config.remoteRoot -Credential $Creds
    $Destination = $config.tempDriveLetter + ":" + "\" + $Year + "\" + $ClientName + "\" + $Day + "\"
    
    try {

        # Try to move the item
        Move-Item -Path ([string]::Format("{0}\$NewFileName",$OriginalFile.DirectoryName)) -Destination ($Destination + $NewFileName) -ErrorAction Stop

    } catch [System.IO.IOException] {
        
        # Catch IO exception
        # Write to logs
        updateLogs -Message ("Error while trying to move " + ([string]::Format("{0}\$NewFileName",$OriginalFile.DirectoryName)) + " :" + $Error[0].Exception) -Level "ERROR"
        # Attempt a second rename
        try {

            $NewFileName = $NewFileName.Replace($OriginalFile.Extension.ToString(),[string]::Format("-{0}{1}",(get-date).TimeOfDay.ToString().Replace(".","").Substring(0,8).Replace(":","-"),$OriginalFile.Extension))
            $File | Rename-Item -NewName $NewFileName -ErrorAction Stop
            # Try to move the item
            Move-Item -Path ([string]::Format("{0}\$NewFileName",$OriginalFile.DirectoryName)) -Destination ($Destination + $NewFileName) -ErrorAction Stop -Credential $Creds


        } catch {

            updateLogs -Message ("Second rename and move failed: " + $Error[0].Exception + " aborting move") -Level "ERROR"
            # Increment failure count
            $config.failures = [string]([int]$Config.failures + 1)
            $ConfigFile.Save($ConfigFileLocation)

        }


    } catch { # Catch unexpected exception

        updateLogs -Message ("Error while trying to move " + ([string]::Format("{0}\$NewFileName",$OriginalFile.DirectoryName)) + " :" + $Error[0].Exception) -Level "ERROR"
        # Increment failure count
        $config.failures = [string]([int]$Config.failures + 1)
        $ConfigFile.Save($ConfigFileLocation)
    }


    # Test if successful
    $MoveTest = Test-Path -Path ($Destination + $NewFileName)

    if ($MoveTest -eq $false) {

         updateLogs -Message "$ClientName \ $NewFileName unable to be moved to remote destination" -Level "ERROR"

    } else {

        updateLogs -Message "$ClientName \ $NewFileName successfully moved to remote" -Level "INFO"

    }

    # Finally remove our mapped drive
    Remove-PSDrive $config.tempDriveLetter


}


# function to return a reformatted file name
function returnFormattedFileName() {
param(
[parameter(mandatory=$True)][System.IO.FileInfo]$OriginalFile
)
    # Get the original file name
    $OriginalFileName = $OriginalFile.Name


    # Try to match junk at the start
    $Pattern = '.* - '
    $NewName = $OriginalFileName -replace $Pattern,""
    return $NewName
}



##### HIDDEN FUNCTIONS #####

# Simple function to write to log file
function writeToLog() {
param(
[parameter(mandatory=$true)][string]$Message,
[parameter(mandatory=$true)][string]$Level,
[parameter(mandatory=$true)][string]$FullFilePath
)

    $MSG = ([string]::Format("{0} - {1} - {2}", (Get-date -Format H:mm:ss).ToString(), $Level, $Message))
    $MSG | Add-Content -Path $FullFilePath
}

# Simple function to create a folder if it does not exist
function createFolder() {
param(
[parameter(mandatory=$true)][string]$Route,
[parameter(mandatory=$true)][System.Management.Automation.PSCredential]$Creds
)
    # Check if folder exists, need to create mapped drive for passthru of creds to work
    New-PSDrive -Name Z -PSProvider FileSystem -Root $config.remoteRoot -Credential $Creds
    $Destination = $config.tempDriveLetter + ":\" + $Route
    $FolderCheck = Test-Path -Path $Destination

    # If it does not then create it
    if ($FolderCheck -eq $false) {

        New-Item -Path $Destination -ItemType Directory
        Remove-PSDrive $config.tempDriveLetter
        return 1

    } else {
        
        Remove-PSDrive $config.tempDriveLetter
        return 0

        }

}
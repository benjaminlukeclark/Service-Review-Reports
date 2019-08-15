##### EXPOSED FUNCTIONS #####
$config = ([xml](Get-Content "OH NO")).root
$config.SetAttribute("Failures","0")

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
[parameter(mandatory=$true)][string]$Year
)

    # Get route
    $Route = $config.remoteRoot + "\" + $Year
    
    # Encode check in a job to enable running as a different user
    $CheckFolderResults = createFolder -Route $Route


    # Then write to log file if we created the folder
    if ($CheckFolderResults -eq 1) {

        updateLogs -Message "$Year folder created" -Level "TRACE"

    }

}

# Function to attempt creation of Client Folder
function createClientFolder() {
param(
[parameter(mandatory=$true)][string]$ClientName,
[parameter(mandatory=$true)][string]$Year
)

    # Get route
    $Route = $config.remoteRoot + "\" + $Year + "\" + $ClientName

    # Get results
    $CheckFolderResults = createFolder -Route $Route

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
[parameter(mandatory=$true)][string]$Day
)


    # Get route
    $Route = $config.remoteRoot + "\" + $Year + "\" + $ClientName + "\" + $Day

    # Get results
    $CheckFolderResults = createFolder -Route $Route

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
[parameter(mandatory=$True)][System.IO.FileInfo]$OriginalFile
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
    $Destination = $config.remoteRoot + "\" + $Year + "\" + $ClientName + "\" + $Day + "\"
    
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
            Move-Item -Path ([string]::Format("{0}\$NewFileName",$OriginalFile.DirectoryName)) -Destination ($Destination + $NewFileName) -ErrorAction Stop


        } catch {

            updateLogs -Message ("Second rename and move failed: " + $Error[0].Exception + " aborting move") -Level "ERROR"

        }


    } catch { # Catch unexpected exception

        updateLogs -Message ("Error while trying to move " + ([string]::Format("{0}\$NewFileName",$OriginalFile.DirectoryName)) + " :" + $Error[0].Exception) -Level "ERROR"
        # Increment failure count
        $config.SetAttribute("Failures",([int]$Config.Failures + 1))
    }


    # Test if successful
    $MoveTest = Test-Path -Path ($Destination + $NewFileName)

    if ($MoveTest -eq $false) {

         updateLogs -Message "$ClientName \ $NewFileName unable to be moved to remote destination" -Level "ERROR"

    } else {

        updateLogs -Message "$ClientName \ $NewFileName successfully moved to remote" -Level "INFO"

    }


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
[parameter(mandatory=$true)][string]$Route
)
    # Check if folder exists
    $FolderCheck = Test-Path -Path $Route

    # If it does not then create it
    if ($FolderCheck -eq $false) {

        New-Item -Path $Route -ItemType Directory

        return 1

    } else {
        
        return 0

        }

}
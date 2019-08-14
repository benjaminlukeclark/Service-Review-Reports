##### EXPOSED FUNCTIONS #####
$config = ([xml](Get-Content "CAKE")).root

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

    $File | Rename-Item -NewName $NewFileName
    
    # Work out destination
    $Destination = $config.remoteRoot + "\" + $Year + "\" + $ClientName + "\" + $Day + "\"

    # Try the move
    Move-Item -Path ([string]::Format("{0}\$NewFileName",$OriginalFile.DirectoryName)) -Destination ($Destination + $NewFileName)

    # Test if successful
    $MoveTest = Test-Path -Path $Destination

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

        # Patch Compliance
        if ($OriginalFileName -like "*Patch Compliance*") {

            return ("Patch Compliance" + $OriginalFile.Extension)
        }

        if ($OriginalFileName -like "*Software List*") {

            return ("Software List" + $OriginalFile.Extension)
        }

        if ($OriginalFileName -like "*Anti Virus*") {

            return ("Anti Virus Health" + $OriginalFile.Extension)
        }

        if ($OriginalFileName -like "*Computer Audit*") {

            return ("Computer Audit" + $OriginalFile.Extension)
        }

        if ($OriginalFileName -like "*Performance Review*") {

            return ("Performance Review" + $OriginalFile.Extension)
        }

        return $OriginalFileName
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
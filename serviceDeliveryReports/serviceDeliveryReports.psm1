##### EXPOSED FUNCTIONS #####
$config = ([xml](Get-Content "GLADOS")).root

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

        updateLogs -Message "$ClientName folder created" -Level "TRACE"

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

        updateLogs -Message "$Day folder created" -Level "TRACE"

    }


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
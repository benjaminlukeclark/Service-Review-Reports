# Import config with all of our settings
$ConfigFileLocation = "YOUR PATH GOES HERE"
$configFile = ([xml](Get-Content $ConfigFileLocation))
$config = $configFile.Root
# Import modules
Import-Module $config.modulePath
# Set initial failures to 0
$config.failures = "0"
$ConfigFile.Save($ConfigFileLocation)

# Setup Credentials
$credential = Import-CliXml -Path $config.credPath

# Get all the monthly packs that we need
$MonthlyPacks = Get-ChildItem -Path $config.reportRoot| Where Name -like "*Monthly*"
# Get current Day
$CurrentDay = (Get-Date).Date
# Get tomorrow
$Tomorrow = (Get-Date).Date.AddDays(1)
# Attempt creation of Year folder
createYearFolder -Year $CurrentDay.Year -Creds $credential



foreach ($Pack in $MonthlyPacks) {

    
    # Create Client Folder on other end if it does not exist
    $ClientName = $Pack.Name.Replace($config.replaceCriteria,"")
    createClientFolder -ClientName $ClientName -Year $CurrentDay.Year -Creds $credential
    # And then the day folder if it does not exist. First we check to see if day/month is under 10 and if so append a leading 0
    if ([int]$CurrentDay.Day -lt 10) {$dayFolderNum = "0" + $CurrentDay.Day} else {$dayFolderNum = $CurrentDay.Day}
    if ([int]$CurrentDay.Month -lt 10) {$monthFolderNum = "0" + $CurrentDay.Month} else {$monthFolderNum = $CurrentDay.Month}



    # Get all subfolders
    $SubFolders = Get-ChildItem -Path $Pack.PSPath -Directory
    # If we find subfolders then...
    if ($SubFolders -ne $null) {
        # Try to find all files made today
        $Files = $SubFolders[0] | Get-ChildItem -File | Where {($_.CreationTime -gt (Get-Date).Date) -and ($_.CreationTime -lt (Get-Date).Date.AddDays(1)) -and ($_.Name -ne ".folder")}
        # If we didn't find any then output to the log
        if (($Files -eq $null)) {
            updateLogs -Message "Unable to find files for transfer under $ClientName" -Level "INFO"
        } else { #Otherwise we enumerate through all files made today and move them
            # Update logs
            updateLogs -Message ("Found " + $Files.count + " files under $ClientName to transfer") -Level "INFO"
            # create day folder in format of month-day - only do if this there are files to upload
            createDayFolder -ClientName $ClientName -Year $CurrentDay.Year -Day ([string]::Format("{1}-{0}",$dayFolderNum, $monthFolderNum)) -Creds $credential
            # Enumerate through all files made today
            foreach ($File in $Files) {
            # And move them
                moveReport -ClientName $ClientName -Year $CurrentDay.Year -Day ([string]::Format("{1}-{0}",$dayFolderNum, $monthFolderNum)) `
                -NewFileName (returnFormattedFileName -OriginalFile $File) -OriginalFile $File -Creds $credential
                
            }
        }

    } else { # If unable to find any folders
        # Then update log
        updateLogs -Message "Unable to find subfolders under $ClientName" -Level "ERROR"
    }


}


# Finally, check if any files failed to move
if ([int]$config.failures -gt 0) {

    # Check if event source already exists
    $Exists = [System.Diagnostics.EventLog]::SourceExists("ServiceReportTransfer")
    if ($Exists -eq $False) {
        New-EventLog -LogName "Application" -Source "ServiceReportTransfer"

    }
    
    Write-EventLog -LogName Application -Source "ServiceReportTransfer" -EventId 401 `
    -EntryType Error -Message "One or more service reports failed to transfer successfully to the K drive."

}

# At the end set failures to 0 
$config.failures = "0"
$ConfigFile.Save($ConfigFileLocation)
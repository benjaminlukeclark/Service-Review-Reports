$config = ([xml](Get-Content config.xml)).root
Import-Module $config.modulePath

# Get all the monthly packs that we need
$MonthlyPacks = Get-ChildItem -Path $config.reportRoot| Where Name -like "*Monthly*"
# Get current Day
$CurrentDay = (Get-Date).Date
# Get tomorrow
$Tomorrow = (Get-Date).Date.AddDays(1)
# Attempt creation of Year folder
createYearFolder -Year $CurrentDay.Year

foreach ($Pack in $MonthlyPacks) {

    
    # Create Client Folder on other end if it does not exist
    $ClientName = $Pack.Name.Replace($config.replaceCriteria,"")
    createClientFolder -ClientName $ClientName -Year $CurrentDay.Year
    # And then the day folder if it does not exist. First we check to see if day/month is under 10 and if so append a leading 0
    if ([int]$CurrentDay.Day -lt 10) {$dayFolderNum = "0" + $CurrentDay.Day} else {$dayFolderNum = $CurrentDay.Day}
    if ([int]$CurrentDay.Month -lt 10) {$monthFolderNum = "0" + $CurrentDay.Month} else {$monthFolderNum = $CurrentDay.Month}
    # create day folder in format of month-day
    createDayFolder -ClientName $ClientName -Year $CurrentDay.Year -Day ([string]::Format("{1}-{0}",$dayFolderNum, $monthFolderNum))


    $SubFolders = Get-ChildItem -Path $Pack.PSPath -Directory
    $Files = $SubFolders[0] | Get-ChildItem -File | Where {($_.CreationTime -gt (Get-Date).Date) -and ($_.CreationTime -lt (Get-Date).Date.AddDays(1))}


}
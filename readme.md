# ServiceReviewReports

ServiceReviewReports is used to automatically upload ConnectWise Automate reports to a mapped network share.

It will copy all files created that day, and not already uploaded, from the specified report path to the remote path.

## Setup Checklist
- [ ] clone repo
- [ ] edit ConfigSetup.ps1
- [ ] edit ```$ConfigFileLocation``` in serviceDeliveryReports.ps1
- [ ] edit ```$ConfigFileLocation``` in ServiceReportTransfer.psm1
- [ ] OPTIONAL: edit ServiceReportTransfer.ps1 eventlog write
- [ ] OPTIONAL: edit serviceDeliveryReports.psm1 ```returnFormattedFileName``` function

## Installation

To install, first clone the repo locally:

```cmd
git clone https://github.com/Sudoblark/ServiceReviewReports.git
```

Then edit the "ConfigSetup.ps1" file. Items declared are:

**Module Path**

_Direct path to serviceDeliveryReports.psd1 module_

**Report Path**

_Root directory containing Automate reports_

**Replace Criteria**

_Normally automated reports have additional information to client name. For example, ours are "CLIENT - Monthly Packs". The string in here will be replaced and the remainder used to determine Client Names._

**Install Root**

_Directory where you have cloned this to_

**Remote Root**

_Directory where you want to upload files to_

**Failures**

_Used to track failures in each run. Do not edit. Even if you do it'll get overwritten anyway_

Then run to generate the config.xml file:

```PowerShell
.\configSetup.ps1
```

Then update the top of serviceDeliveryReports and ServiceReportTransfer to point to the config file

```PowerShell
$ConfigFileLocation = "OH NO"
```

Change the event log write in ServiceReportTransfer.ps1 to be accurate to your environment:

```PowerShell
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
```

Finally, edit ```returnFormattedFileName``` under serviceDeliveryReports.psm1 if required. This is used to remove auto-generated values placed into the filename by ConnectWise Automate.

```PowerShell
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
```

## Usage

When run manually this will create, in the specified remote root, the following folder structure:
```
-Year
-- Client
--- Month-Day
---- Files
```

For example:
```
- 2019
-- Client A
--- 01-12
---- HelloWorld.xt
-- Client B
-- 01-12
---- HelloWorld.txt
```

If you want a regular transfer of files, the recommended approach is to setup a scheduled task running as a user with access to both remote and local. A good way to do this is to map the remote as a drive for that user, then make the scheduled task run in that user context.

Log files are also created in a flat structure of dd-MM-yy under installRoot\Logs:
```
- installRoot
-- Logs
--- 15-08-2019.txt
```
With content similar to below:

```
9:24:23 - FATAL - Log file created
9:24:23 - INFO - Unable to find files for transfer under ClientA
9:24:23 - INFO - Found 2 files under ClientB to transfer
9:24:23 - TRACE - 2019 \ ClientB \ 08-15 folder created
9:24:23 - INFO - ClientB \ Hello.txt successfully moved to remote
9:24:23 - ERROR - Error while trying to move Z:\ReportDeliveries\ClientB - Monthly Pack\Adhoc\Hello2.txt :
9:24:23 - ERROR - Error while trying to move Z:\ReportDeliveries\ClientB - Monthly Pack\Adhoc\Hello2.txt :
9:24:23 - ERROR - Second rename and move failed:  aborting move
9:24:23 - ERROR - ClientB \ Hello2.txt unable to be moved to remote destination

```

If the file being copied exists locally or remotely the program attempts to rename it, and append -hh-mm-ss to the end to make it unique. If any files failed to be moved then an event is written to the eventlog. 

If you are using this to move ConnectWise Automate reports, then you can quite easily setup an event log monitor so you are notified of any failures. I haven't used other RMM Platforms, but I'm sure they'll have some capability to monitor event logs.

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

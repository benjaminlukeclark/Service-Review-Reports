# ServiceReviewReports

ServiceReviewReports is used to automatically upload ConnectWise Automate reports to a mapped network share.

It will copy all files created that day, and not already uploaded, from the specified report path to the remote path.

## Installation

To install, first clone the repo locally:

```cmd
git clone https://github.com/Sudoblark/ServiceReviewReports.git
```

Then edit the "ConfigSetup.ps1" file. Items declared are:

- Module Path
Direct path to serviceDeliveryReports.psd1 module

- Report Path
Root directory containing Automate reports

- Replace Criteria
Normally automated reports have additional information to client name. For example, ours are "CLIENT - Monthly Packs". The string in here will be replaced and the remainder used to determine Client Names.

- Install Root
Directory where you have cloned this to

- Remote Root
Directory where you want to upload files to

Then run to generate the config.xml file:

```PowerShell
.\configSetup.ps1
```

Then update the top of serviceDeliveryReports and/or ServiceReportTransfer to point to the config file

```PowerShell
$config = ([xml](Get-Content "YOUR XML HERE")).root

## Usage

When run manually this will create, in the specified remote root, the following folder structure:
-Year
-- Client
--- Month-Day
---- Files

For example:
- 2019
-- Client A
--- 01-12
---- HelloWorld.xt
-- Client B
-- 01-12
---- HelloWorld.txt

If you want a regular transfer of files, the recommended approach is to setup a scheduled task running as a user with access to both remote and local. A good way to do this is to map the remote as a drive for that user, then make the scheduled task run in that user context.

Log files are also created in a flat structure of dd-MM-yy under installRoot\Logs


## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[MIT](https://choosealicense.com/licenses/mit/)
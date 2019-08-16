# Import config with all of our settings
$ConfigFileLocation = "OUR PATH GOES HERYE"
$configFile = ([xml](Get-Content $ConfigFileLocation))
$config = $configFile.Root

# Save credentials
$credential = Get-Credential
$credential | Export-CliXml -Path $config.credPath
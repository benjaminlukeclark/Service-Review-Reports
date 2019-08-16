@'
<root>
    <modulePath>FULL PATH TO serviceDeliveryReports.psd1 FILE</modulePath>
    <reportRoot>ROOT OF WHERE AUTOMATE REPORTS ARE, E.G. C:\LTSHARE\REPORTDELIVERIES/reportRoot>
    <replaceCriteria>STUFF TO REPLACE IN FILE NAME</replaceCriteria>
    <installRoot>ROOT OF WHERE YOU'VE EXTRACTED THIS PROGRAM</installRoot>
    <remoteRoot>ROOT OF REMOTE E.G. \\HELLO-WORLD\MYSHARE</remoteRoot>
    <failures>0</failures>
    <credPath>PATH TO SAVE REMOTE CREDENTIALS TO</credPath>
    <tempDriveLetter>LETTER OF TEMP DRIVE CREATED FOR USE OF CREDENTIALS ON REMOTE ROOT</tempDriveLetter>
</root>
'@ | Out-File config.xml
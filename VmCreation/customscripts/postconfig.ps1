Param([Parameter(Mandatory=$True)]$vmname,[Parameter(Mandatory=$True)]$dbvmname,[Parameter(Mandatory=$True)]$db02vmname,[Parameter(Mandatory=$True)]$domainname,[Parameter(Mandatory=$True)]$domainuser,[Parameter(Mandatory=$True)]$domainpasswd,[Parameter(Mandatory=$True)]$oupath,[Parameter(Mandatory=$True)]$baseappvm,[Parameter(Mandatory=$True)]$basedbvm,[parameter(Mandatory=$True)]$basedb02vm,[Parameter(Mandatory=$True)]$Authpwd,[Parameter(Mandatory=$True)]$ODBCusid,[Parameter(Mandatory=$True)]$ODBCpsd)

Get-WmiObject -Class Win32_volume -Filter 'DriveType=5' | Select-Object -First 1 | Set-WmiInstance -Arguments @{DriveLetter='U:'}
$dataDisk = Get-Partition -DiskNumber 3
if ($dataDisk[1].DriveLetter -ne 'F') 
{
    Set-Partition -PartitionNumber $dataDisk[1].PartitionNumber -DiskNumber $dataDisk[1].DiskNumber -NewDriveLetter F
}
else 
{
    Write-Output "DEBUG:: Data Disk has Drive Letter: $($dataDisk[1].DriveLetter)"
}

# Create a new folder in C: drive
New-Item -ItemType directory -Path C:\IISKeys

# Download the config files to C:\IISKeys folder
Invoke-WebRequest -Uri https://mgidcoddemodiag.blob.core.windows.net/dcodclone/IISKEYS/configEncKeyAes.key -outfile 'C:\IISKEYS/configEncKeyAes.key'
Invoke-WebRequest -Uri https://mgidcoddemodiag.blob.core.windows.net/dcodclone/IISKEYS/applicationHost.config -outfile 'C:\IISKEYS/applicationHost.config'
Invoke-WebRequest -Uri https://mgidcoddemodiag.blob.core.windows.net/dcodclone/IISKEYS/administration.config  -outfile 'C:\IISKEYS/administration.config'
$appvmname= $vmname
$dbvmname= $dbvmname
$db02vmname= $db02vmname

#ODBC Connection Parameters
$dsn = Get-OdbcDsn
$usid = $ODBCusid
$psd = $ODBCpsd
$authpwd = $Authpwd
$pbservername=$baseappvm
$dbservername=$basedbvm
$db02servername= $basedb02vm

$LogFile = New-Item -Path 'C:\DCTDeploymentLog\Logfile.txt' -ItemType File -Force

$policylogFile = New-Item -Path 'C:\DCTDeploymentLog\Policy\PolicyLog.txt' -ItemType File -Force
$Policy = Get-ChildItem -recurse -Path F:\DuckCreek\Policy -Include *.xml,*.config,*.json | Select-String -pattern $dbservername, $pbservername | group path |select name

$billinglogfile = New-Item -Path 'C:\DCTDeploymentLog\Billing\\BillingLog.txt' -ItemType File -Force
$Billing = Get-ChildItem -recurse -Path F:\DuckCreek\Billing -Include *.xml,*.config,*.json | Select-String -pattern $dbservername, $pbservername | group path |select name

$claimslogfile = New-Item -Path 'C:\DCTDeploymentLog\Claims\ClaimsLog.txt' -ItemType File -Force
$Claims = Get-ChildItem -recurse -Path F:\DuckCreek\Claims, F:\DuckCreek\Claims.services -Include *.xml,*.config,*.json | Select-String -pattern $dbservername, $pbservername | group path |select name

$Insightslogfile = New-Item -Path 'C:\DCTDeploymentLog\Insights\InsightsLog.txt' -ItemType File -Force
$Insights = Get-ChildItem -recurse -Path F:\DuckCreek\Insights.Extract.Server, F:\DuckCreek\Insights.Portal -Include *.xml,*.config,*.json | Select-String -pattern $db02servername,$dbservername, $pbservername  | group path |select name 


function detaillogfunc {
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False)]
    [ValidateSet("INFO","WARN","ERROR","FATAL","DEBUG")]
    [String]
    $Level = "INFO",

    [Parameter(Mandatory=$True)]
    [string]
    $Message,

    [Parameter(Mandatory=$True)]
    [string]
    $logpathfile
    )

    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $Line = "$Stamp $Level $Message"
    If($logpathfile) {
        Add-Content $logpathfile -Value $Line
    }
    Else {
        Write-Output $Line
    }
}

detaillogfunc -Message " Start..." -logpathfile $policylogFile
foreach($policypath in $Policy){

    try {
        $linenumber = Get-Content $policypath.Name | Select-String $pbservername
        $path = (Get-Content $policypath.Name) | Foreach-Object {$_ -replace $pbservername,$appvmname} | Set-Content $policypath.Name
        $pathlinenumber = $linenumber.LineNumber
        $pathname = $policypath.Name
        $messageupdate = "Path is: $pathname and LineNumbers are: $pathlinenumber"
        if($pathlinenumber -ne $null){
        detaillogfunc -Message "$messageupdate" -logpathfile $policylogFile
        }
   }
   catch {
    detaillogfunc -Message "Exception Occured " -logpathfile $policylogFile
    detaillogfunc -Message $_.Exception.Message -logpathfile $policylogFile
       
   }

   try {
       $linenumber1 = Get-Content $policypath.Name | Select-String $dbservername
       $path1 = (Get-Content $policypath.Name) | Foreach-Object {$_ -replace $dbservername,$dbvmname} |Set-Content $policypath.Name
       $pathlinenumber1 = $linenumber1.LineNumber
       $pathname1 = $policypath.Name
       $messageupdate1 = "Path is: $pathname1 and LineNumbers are: $pathlinenumber1"
        if($pathlinenumber1 -ne $null){
       detaillogfunc -Message "$messageupdate1" -logpathfile $policylogFile
       }
   }
   catch {
    detaillogfunc -Message "Exception Occured " -logpathfile $policylogFile
    detaillogfunc -Message $_.Exception.Message -logpathfile $policylogFile
       
   }
}
detaillogfunc -Message " Stop..." -logpathfile $policylogFile
detaillogfunc -Message " Start..." -logpathfile $billinglogfile
foreach($billingpath in $Billing){
  try {
    $linenumber = Get-Content $billingpath.Name | Select-String $pbservername
    $path = (Get-Content $billingpath.Name) | Foreach-Object {$_ -replace $pbservername,$appvmname} |Set-Content $billingpath.Name
    $pathlinenumber = $linenumber.LineNumber
    $pathname = $billingpath.Name
    $messageupdate = "Path is: $pathname and LineNumbers are: $pathlinenumber"
     if($pathlinenumber -ne $null){
    detaillogfunc -Message $messageupdate -logpathfile $billinglogfile
    }
  }
  catch {
    detaillogfunc -Message "Exception Occured " -logpathfile $billinglogfile
    detaillogfunc -Message $_.Exception.Message -logpathfile $billinglogfile
    
  }
  try{
     $linenumber1 = Get-Content $billingpath.Name | Select-String $dbservername
    $path1 = (Get-Content $billingpath.Name) | Foreach-Object {$_ -replace $dbservername,$dbvmname} |Set-Content $billingpath.Name
    $pathlinenumber1 = $linenumber1.LineNumber
    $pathname1 = $billingpath.Name
    $messageupdate1 = "Path is: $pathname1 and LineNumbers are: $pathlinenumber1"
     if($pathlinenumber1 -ne $null){
    detaillogfunc -Message $messageupdate1 -logpathfile $billinglogfile
    }
   }
  catch {
    detaillogfunc -Message "Exception Occured " -logpathfile $billinglogfile
    detaillogfunc -Message $_.Exception.Message -logpathfile $billinglogfile
    
  }
}
detaillogfunc -Message " Stop..." -logpathfile $billinglogfile
detaillogfunc -Message " Start..." -logpathfile $claimslogfile

foreach($claimspath in $Claims){
  try {
    $linenumber = Get-Content $claimspath.Name | Select-String $pbservername
    $path = (Get-Content $claimspath.Name) | Foreach-Object {$_ -replace $pbservername,$appvmname} |Set-Content $claimspath.Name
    $pathlinenumber = $linenumber.LineNumber
    $pathname = $claimspath.Name
    $messageupdate = "Path is: $pathname and LineNumbers are: $pathlinenumber"
     if($pathlinenumber -ne $null){
    detaillogfunc -Message "$messageupdate" -logpathfile $claimslogfile
    }
 }
  catch {
    detaillogfunc -Message "Exception Occured " -logpathfile $claimslogfile
    detaillogfunc -Message $_.Exception.Message -logpathfile $claimslogfile
    
}

  try {
  $linenumber1 = Get-Content $claimspath.Name | Select-String $dbservername
    $path1 = (Get-Content $claimspath.Name) | Foreach-Object {$_ -replace $dbservername,$dbvmname} |Set-Content $claimspath.Name
    $pathlinenumber1 = $linenumber1.LineNumber
    $pathname1 = $claimspath.Name
    $messageupdate1 = "Path is: $pathname1 and LineNumbers are: $pathlinenumber1"
     if($pathlinenumber1 -ne $null){
    detaillogfunc -Message "$messageupdate1" -logpathfile $claimslogfile
    }
   }
  catch {
    detaillogfunc -Message "Exception Occured " -logpathfile $claimslogfile
    detaillogfunc -Message $_.Exception.Message -logpathfile $claimslogfile
    
  }
}
detaillogfunc -Message " Stop..." -logpathfile $claimslogfile
detaillogfunc -Message " Start..." -logpathfile $Insightslogfile
foreach($insightpath in $Insights){
  try {
    $linenumber = Get-Content $insightpath.Name | Select-String $db02servername
    $path = (Get-Content $insightpath.Name) | Foreach-Object {$_ -replace $db02servername, $db02vmname} |Set-Content $insightpath.Name
    $pathlinenumber = $linenumber.LineNumber
    $pathname = $insightpath.Name
    $messageupdate = "Path is: $pathname and LineNumbers are: $pathlinenumber"
     if($pathlinenumber -ne $null){
        detaillogfunc -Message $messageupdate -logpathfile $Insightslogfile
      }
  }
  catch {
    detaillogfunc -Message "Exception Occured " -logpathfile $Insightslogfile
    detaillogfunc -Message $_.Exception.Message -logpathfile $Insightslogfile
    
  }

  try {
    $linenumber1 = Get-Content $insightpath.Name | Select-String $dbservername
    $path1 = (Get-Content $insightpath.Name) | Foreach-Object {$_ -replace $dbservername,$dbvmname} |Set-Content $insightpath.Name
    $pathlinenumber1 = $linenumber1.LineNumber
    $pathname1 = $insightpath.Name
    $messageupdate1 = "Path is: $pathname1 and LineNumbers are: $pathlinenumber1"
     if($pathlinenumber1 -ne $null){
       detaillogfunc -Message "$messageupdate1" -logpathfile $Insightslogfile
      }
  }
  catch {
    detaillogfunc -Message "Exception Occured " -logpathfile $Insightslogfile
    detaillogfunc -Message $_.Exception.Message -logpathfile $Insightslogfile
  }

  try {
    $linenumber2 = Get-Content $insightpath.Name | Select-String $pbservername
    $path2 = (Get-Content $insightpath.Name) | Foreach-Object {$_ -replace $pbservername,$appvmname} |Set-Content $insightpath.Name
    $pathlinenumber2 = $linenumber2.LineNumber
    $pathname2 = $insightpath.Name
    $messageupdate2 = "Path is: $pathname2 and LineNumbers are: $pathlinenumber2"
     if($pathlinenumber2 -ne $null){
      detaillogfunc -Message "$messageupdate2" -logpathfile $Insightslogfile
    }
  }
  catch {
    detaillogfunc -Message "Exception Occured " -logpathfile $Insightslogfile
    detaillogfunc -Message $_.Exception.Message -logpathfile $Insightslogfile
  }
  
}
detaillogfunc -Message " Stop..." -logpathfile $Insightslogfile
# Domain joining 
$LUser = $domainuser
$LPswd = $domainpasswd
$domain_name = $domainname
$OUPath = $oupath
$Hostname = $appvmname

try{
  detaillogfunc -Message " Domain Joining..." -logpathfile $LogFile
  $guest_credentials = New-Object System.Management.Automation.PSCredential($LUser, (ConvertTo-SecureString $LPswd -AsPlainText -Force))
  Add-Computer -DomainName $domain_name -OUPath $OUPath -Credential $guest_credentials
  $guest_session = New-PSSession -ComputerName $Hostname -Credential $guest_credentials
  Invoke-Command -ComputerName $Hostname -Credential $guest_credentials -ScriptBlock {$domain_name = $args[0]; $OUPath = $args; $domain_credentials = $args[2]; Add-Computer -DomainName $domain_name -OUPath $OUPath -Credential $domain_credentials -Force -ReStart -PassThru -Verbose} -ArgumentList @($DName, $OUName, $guest_credentials)
  detaillogfunc -Message " Domain Joined..." -logpathfile $LogFile
}
catch{
  detaillogfunc -Message "Exception Occured " -logpathfile $LogFile
  detaillogfunc -Message $_.Exception.Message -logpathfile $LogFile
}
## IIS Config level Changes
try{
  detaillogfunc -Message " Enabiling IIS config..." -logpathfile $LogFile
  $KeyEncryptionPassword = ConvertTo-SecureString -AsPlainText -String $domainpasswd -Force
  $Password = ConvertTo-SecureString -AsPlainText -String $domainpasswd -Force
  Enable-IISSharedConfig -PhysicalPath "C:\IISKEYS" -KeyEncryptionPassword $KeyEncryptionPassword -UserName "Dctautovm\svcusr" -Password $Password
  detaillogfunc -Message " Enabled IIS Config..." -logpathfile $LogFile
}
catch{
  detaillogfunc -Message "Exception Occured " -logpathfile $LogFile
  detaillogfunc -Message $_.Exception.Message -logpathfile $LogFile
}
# ReStarting IIS service
try{
  detaillogfunc -Message " IIS Restarting..." -logpathfile $LogFile
  iisreset
  Start-Sleep -s 5
  detaillogfunc -Message " IIS Restarted..." -logpathfile $LogFile
}
catch{
  detaillogfunc -Message "Exception Occured " -logpathfile $LogFile
  detaillogfunc -Message $_.Exception.Message -logpathfile $LogFile
}
#DCOD License Mapping
try{
  detaillogfunc -Message " License Mapping..." -logpathfile $LogFile
  New-Item -ItemType directory -Path C:\License
  Invoke-WebRequest -Uri https://mgidcoddemodiag.blob.core.windows.net/dcodclone/LIcenses/RunLicenseMaker.ps1 -outfile 'C:\License\RunLicenseMaker.ps1'
  detaillogfunc -Message "Policy License Mapping..." -logpathfile $LogFile
  C:\License\RunLicenseMaker.ps1  F:\DuckCreek\Policy
  detaillogfunc -Message "Billing License Mapping..." -logpathfile $LogFile
  C:\License\RunLicenseMaker.ps1 F:\DuckCreek\Billing
  detaillogfunc -Message "Claims License Mapping..." -logpathfile $LogFile
  C:\License\RunLicenseMaker.ps1 F:\DuckCreek\Claims
  detaillogfunc -Message "Insights License Mapping..." -logpathfile $LogFile
  C:\License\RunLicenseMaker.ps1 F:\DuckCreek\Insights.Extract.Server
  detaillogfunc -Message "Restarting DuckCreekAsyncQueueBilling Service..." -logpathfile $LogFile
  ReStart-Service -Name "DuckCreekAsyncQueueBilling"
  detaillogfunc -Message "Restarting DuckCreekAsyncQueuePolicy Service..." -logpathfile $LogFile
  ReStart-Service -Name "DuckCreekAsyncQueuePolicy"
  detaillogfunc -Message "Restarting DuckCreekBillingMSMQListener Service..." -logpathfile $LogFile
  ReStart-Service -Name "DuckCreekBillingMSMQListener"
  detaillogfunc -Message "Restarting DuckCreekScheduledRequest Service..." -logpathfile $LogFile
  ReStart-Service -Name "DuckCreekScheduledRequest"
  detaillogfunc -Message "Restarting DuckCreekSessionCleanupBilling Service..." -logpathfile $LogFile
  ReStart-Service -Name "DuckCreekSessionCleanupBilling"
  detaillogfunc -Message "Restarting DuckCreekSessionCleanupPolicy Service..." -logpathfile $LogFile
  ReStart-Service -Name "DuckCreekSessionCleanupPolicy"
  detaillogfunc -Message "Restarting DuckCreekBillingAutoRetry Service..." -logpathfile $LogFile
  ReStart-Service -Name "DuckCreekBillingAutoRetry"
  detaillogfunc -Message "Restarting AEF.Event.WindowsService_Party Service..." -logpathfile $LogFile
  ReStart-Service -Name "AEF.Event.WindowsService_Party"
  detaillogfunc -Message "Restarting AEF.Event.WindowsService..." -logpathfile $LogFile
  ReStart-Service -Name "AEF.Event.WindowsService"
  Start-Sleep -s 5
}
catch{
  detaillogfunc -Message "Exception Occured " -logpathfile $LogFile
  detaillogfunc -Message $_.Exception.Message -logpathfile $LogFile
}
#ODBC connection configuration
try{
  detaillogfunc -Message "ODBC Connection establishing..." -logpathfile $LogFile
  foreach($dsnvalues in $dsn)
  {
    Set-OdbcDsn -Name $dsnvalues.Name -DriverName $dsnvalues.DriverName -Platform $dsnvalues.Platform -DSNType $dsnvalues.DsnType -SetPropertyValue @("server="+$dbvmName)
    $conn = new-object system.data.odbc.odbcconnection
    $conn.connectionString = "Driver=" + $dsnvalues.DriverName + ";"+ "server="+ $dsnvalues.Attribute.Server +";"+ "database="+$dsnvalues.Attribute.Database +";"+ "Uid="+$usid +";"+ "Pwd="+$psd +";"+ "Authentication=" +$authpwd
    $conn.open()
  }
  Start-Sleep -s 5
  detaillogfunc -Message "ODBC Connection established..." -logpathfile $LogFile
}
catch{
  detaillogfunc -Message "Exception Occured " -logpathfile $LogFile
  detaillogfunc -Message $_.Exception.Message -logpathfile $LogFile
}
#reStarting VM
try{
  detaillogfunc -Message "Vm Restarted..." -logpathfile $LogFile
  ReStart-Computer
}
catch{
  detaillogfunc -Message "Exception Occured " -logpathfile $LogFile
  detaillogfunc -Message $_.Exception.Message -logpathfile $LogFile
}

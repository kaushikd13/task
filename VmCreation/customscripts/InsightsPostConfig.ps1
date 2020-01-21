#Param([Parameter(Mandatory=$True)]$vmname,[Parameter(Mandatory=$True)]$domainname,[Parameter(Mandatory=$True)]$domainuser,[Parameter(Mandatory=$True)]$domainpasswd,[Parameter(Mandatory=$True)]$oupath,[Parameter(Mandatory=$True)]$dbvmname,[Parameter(Mandatory=$True)]$db02vmname,[Parameter(Mandatory=$True)]$basedbvm,[parameter(Mandatory=$True)]$basedb02vm,[Parameter(Mandatory=$True)]$ODBCusid,[Parameter(Mandatory=$True)]$ODBCpsd)
Param([Parameter(Mandatory=$True)]$dbvmname ,[Parameter(Mandatory=$True)]$db02vmname,[Parameter(Mandatory=$True)]$basedbvm,[Parameter(Mandatory=$True)]$basedb02vm,[Parameter(Mandatory=$True)]$domainname,[Parameter(Mandatory=$True)]$domainuser,[Parameter(Mandatory=$True)]$domainpasswd,[Parameter(Mandatory=$True)]$oupath,[parameter(Mandatory=$True)]$ODBCusid,[Parameter(Mandatory=$True)]$ODBCpsd)
$policylogFile = New-Item -Path 'C:\DCTDeploymentLog\Policy\InsightsLog.txt' -ItemType File -Force
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
$logFile = New-Item -Path 'C:\DCTDeploymentLog\LogFile\Log.txt' -ItemType File -Force
Start-Sleep -s 10
# $appvmname= $vmname

# Domain joining 

$LUser = $domainuser

$LPswd = $domainpasswd
$domain_name = $domainname
$OUPath = $oupath
$Hostname = $db02vmname
$guest_credentials = New-Object System.Management.Automation.PSCredential($LUser, (ConvertTo-SecureString $LPswd -AsPlainText -Force))
Add-Computer -DomainName $domain_name -OUPath $OUPath -Credential $guest_credentials
$guest_session = New-PSSession -ComputerName $Hostname -Credential $guest_credentials
Invoke-Command -ComputerName $Hostname -Credential $guest_credentials -ScriptBlock {$domain_name = $args[0]; $OUPath = $args; $domain_credentials = $args[2]; Add-Computer -DomainName $domain_name -OUPath $OUPath -Credential $domain_credentials -Force -Restart -PassThru -Verbose} -ArgumentList @($DName, $OUName, $guest_credentials)

Start-Sleep -s 30
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
detaillogfunc -Message "Start...." -logpathfile $logFile
$DB01="'"+$basedbvm+"'"
$DB01clone="'"+$dbvmname+"'"
$DB02="'"+$basedb02vm+"'"
$DB02clone="'"+$db02vmname+"'"
$SQLDBName = "DCTYodilIDS_Config"

 detaillogfunc -Message "$DB01" -logpathfile $logFile
 detaillogfunc -Message "$DB01clone" -logpathfile $logFile
 detaillogfunc -Message "$DB02" -logpathfile $logFile
 detaillogfunc -Message "$DB02clone" -logpathfile $logFile
 $status=(Get-Service -name MSSQLSERVER).Status
while ((Get-Service -name MSSQLSERVER).Status -ne 'Running') {
    Start-Service MSSQLSERVER
    detaillogfunc -Message "SQL Status inside:$status" -logpathfile $logFile
}
$status=(Get-Service -name MSSQLSERVER).Status
try {
    detaillogfunc -Message "SQL Status outside:$status" -logpathfile $logFile
    $sqlConn = New-Object System.Data.SqlClient.SqlConnection
    $SqlConn.ConnectionString = "Server = '$db02vmname'; Database = $SQLDBName; User ID= $ODBCusid; Password= $ODBCpsd" 
    $sqlConn.Open()  
}
catch {
    detaillogfunc -Message "Exception Occured while established sql connection" -logpathfile $logFile
    detaillogfunc -Message $_.Exception.Message -logpathfile $logFile
}


while($sqlConn.State -ne 'Open') {
    $sqlConn.Open()
    detaillogfunc -Message "SQL Connection inside:$sqlConn.State" -logpathfile $logFile
 }
detaillogfunc -Message "SQL Connection Outside: $sqlConn.State" -logpathfile $logFile
Start-Sleep -s 20
detaillogfunc -Message "Connection established" -logpathfile $logFile

try {
detaillogfunc -Message "Entered Into Try" -logpathfile $logFile

$sqlcmd = New-Object System.Data.SqlClient.SqlCommand
$sqlcmd.Connection = $sqlConn
detaillogfunc -Message "Connection...." -logpathfile $logFile
$query = "update DCTYodilIDS_Config.Duck.ConnectString set DataSourceName=$DB01clone where DataSourceName=$DB01 ; update DCTYodilIDS_Config.Duck.ConnectString set DataSourceName=$DB02clone where DataSourceName=$DB02"
detaillogfunc -Message "$query" -logpathfile $logFile
$sqlcmd.CommandText = $query
$sqlcmd.ExecuteNonQuery()
detaillogfunc -Message "Updated" -logpathfile $logFile

New-Object System.Data.SqlClient.SqlDataAdapter $sqlcmd
detaillogfunc -Message "Connection Closed" -logpathfile $logFile
detaillogfunc -Message "Stop..." -logpathfile $logFile
$sqlConn.Close()
}
catch {
    detaillogfunc -Message "Exception Occured" -logpathfile $logFile
    detaillogfunc -Message $_.Exception.Message -logpathfile $logFile
}
$Ssispaths = Get-ChildItem -recurse -Path F:\ | Select-String -pattern $basedb02vm | group path |select name

foreach($ssispath in $Ssispaths){

    try {
        $linenumber = Get-Content $ssispath.Name | Select-String $basedb02vm
        $path = (Get-Content $ssispath.Name) | Foreach-Object {$_ -replace $basedb02vm,$db02vmname} | Set-Content -encoding utf8 $ssispath.Name
        $pathlinenumber = $linenumber.LineNumber
        $pathname = $ssispath.Name
        $messageupdate = "Path is: $pathname and LineNumbers are: $pathlinenumber"
        if($pathlinenumber -ne 0){
        detaillogfunc -Message "$messageupdate" -logpathfile $policylogFile
        }
   }
   catch {
       Break
   }
}
#restarting VM
Restart-Computer
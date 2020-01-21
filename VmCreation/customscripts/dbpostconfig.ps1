
Param([Parameter(Mandatory=$True)]$vmname,[Parameter(Mandatory=$True)]$domainname,[Parameter(Mandatory=$True)]$domainuser,[Parameter(Mandatory=$True)]$domainpasswd,[Parameter(Mandatory=$True)]$oupath)

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

Start-Sleep -s 10
# $appvmname= $vmname

# Domain joining 

$LUser = $domainuser

$LPswd = $domainpasswd
$domain_name = $domainname
$OUPath = $oupath
$Hostname = $vmname
$guest_credentials = New-Object System.Management.Automation.PSCredential($LUser, (ConvertTo-SecureString $LPswd -AsPlainText -Force))
Add-Computer -DomainName $domain_name -OUPath $OUPath -Credential $guest_credentials
$guest_session = New-PSSession -ComputerName $Hostname -Credential $guest_credentials
Invoke-Command -ComputerName $Hostname -Credential $guest_credentials -ScriptBlock {$domain_name = $args[0]; $OUPath = $args; $domain_credentials = $args[2]; Add-Computer -DomainName $domain_name -OUPath $OUPath -Credential $domain_credentials -Force -Restart -PassThru -Verbose} -ArgumentList @($DName, $OUName, $guest_credentials)

#restarting VM
Restart-Computer
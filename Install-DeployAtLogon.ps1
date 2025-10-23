<#
.SYNOPSIS
Creates a helper PowerShell script and registers a scheduled task to run it at every user logon.
The helper script can be customized to perform any desired actions at logon.

This script ensures the helper script is placed in a directory, sets up the scheduled task for all users,
and creates a registry key for detection purposes (e.g., for Intune or other management tools).
#>

# MODIFYABLE PARAMETERS
$taskName   = "Component_DeployAtLogon" # Define the name of the scheduled task
$taskDescription = "Describe the action of the scheduled task here." # Add a description of the scheduled task
$Author = "Joey Verlinden" # Define the author of the scheduled task/script

# STATIC PARAMETERS
$scriptDir  = "C:\ProgramData\CustomDeviceManagement\"
$scriptPath = Join-Path $scriptDir "$taskName.ps1"

# CREATE SCRIPT DIRECTORY
if (-not (Test-Path -Path $scriptDir)) {
    New-Item -Path $scriptDir -ItemType Directory -Force | Out-Null
}

# EXECUTION SCRIPT
$helper = @'
###################### START CUSTOM EXECUTION SCRIPT ######################





###################### END CUSTOM EXECUTION SCRIPT ######################
'@

Set-Content -Path $scriptPath -Value $helper -Force -Encoding UTF8

# SCHEDULED TASK CREATION
try {
    # Remove if exists
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    }

    $dateNow = (Get-Date).ToString("o")

    $xml = @"
<?xml version="1.0"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>$dateNow</Date>
    <Author>$Author</Author>
    <Description>$taskDescription</Description>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
    </LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id="Users">
      <GroupId>S-1-5-32-545</GroupId>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions>
    <Exec>
      <Command>PowerShell.exe</Command>
      <Arguments><![CDATA[-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "$scriptPath"]]></Arguments>
    </Exec>
  </Actions>
</Task>
"@

    Register-ScheduledTask -TaskName $taskName -Xml $xml -Force
} catch {
    Write-Error "Failed to create scheduled task: $($_.Exception.Message)"
}

# Create registry key to indicate successful installation and detection method for Intune
$Path = "HKLM:\SOFTWARE\CustomDeviceManagement\$taskName"
$Key = "ScriptInstalled" 
$KeyFormat = "dword"
$Value = "1"

if(!(Test-Path $Path)){New-Item -Path $Path -Force}
if(!$Key){Set-Item -Path $Path -Value $Value

}else{Set-ItemProperty -Path $Path -Name $Key -Value $Value -Type $KeyFormat}

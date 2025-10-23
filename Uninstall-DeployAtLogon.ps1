# MODIFYABLE PARAMETERS
$taskName  = "Component_DeployAtLogon" # Define the name of the scheduled task

# STATIC PARAMETERS
$scriptDir = "C:\ProgramData\CustomDeviceManagement\"

# REMOVE SCHEDULED TASK
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
}

# REMOVE SCRIPT FILE
$scriptFile = "$scriptDir$taskName.ps1"
if (Test-Path $scriptFile) {
    Remove-Item $scriptFile -ErrorAction SilentlyContinue

}

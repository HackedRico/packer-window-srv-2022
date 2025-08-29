# Cleanup script for Windows Server 2022 Packer build
Write-Host "Starting cleanup process..."

# Clear Windows Update downloads
Write-Host "Cleaning Windows Update cache..."
Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
Remove-Item C:\Windows\SoftwareDistribution\Download\* -Recurse -Force -ErrorAction SilentlyContinue
Start-Service wuauserv -ErrorAction SilentlyContinue

# Clean temporary files
Write-Host "Cleaning temporary files..."
Remove-Item C:\Windows\Temp\* -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item C:\Temp\* -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue

# Clean user profiles temp folders
Get-ChildItem C:\Users\* | ForEach-Object {
    Remove-Item "$($_.FullName)\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
}

# Clear event logs
Write-Host "Clearing event logs..."
Get-EventLog -LogName * | ForEach-Object { Clear-EventLog $_.Log -ErrorAction SilentlyContinue }

# Clean Windows logs
Remove-Item C:\Windows\Logs\* -Recurse -Force -ErrorAction SilentlyContinue

# Clean IIS logs if present
if (Test-Path C:\inetpub\logs\LogFiles) {
    Remove-Item C:\inetpub\logs\LogFiles\* -Recurse -Force -ErrorAction SilentlyContinue
}

# Clear recent items
Remove-Item "$env:APPDATA\Microsoft\Windows\Recent\*" -Force -ErrorAction SilentlyContinue

# Clean prefetch
Remove-Item C:\Windows\Prefetch\* -Force -ErrorAction SilentlyContinue

# Clean Windows Installer cache (be careful with this)
# Remove-Item C:\Windows\Installer\$PatchCache$\* -Recurse -Force -ErrorAction SilentlyContinue

# Clear DNS cache
ipconfig /flushdns

# Clear ARP table
arp -d *

# Run disk cleanup
Write-Host "Running disk cleanup..."
cleanmgr /sagerun:1

# Defrag the disk (optional, can be time-consuming)
# defrag C: /O

# Clear PowerShell history
Remove-Item "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" -Force -ErrorAction SilentlyContinue

# Zero free space (optional - makes image smaller but takes time)
# Write-Host "Zeroing free space (this may take a while)..."
# sdelete -z c:

# Disable hibernation to save space
powercfg -h off

# Clear page file
$pagefile = Get-WmiObject -Class Win32_ComputerSystem
$pagefile.AutomaticManagedPagefile = $false
$pagefile.Put()

# Remove page file
$pagefileSetting = Get-WmiObject -Class Win32_PageFileSetting
if ($pagefileSetting) {
    $pagefileSetting.Delete()
}

Write-Host "Cleanup completed successfully!"

# Final system information
Write-Host "=== Final System Information ==="
Write-Host "Available Disk Space: $((Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace / 1GB) GB"
Write-Host "Total Disk Space: $((Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'").Size / 1GB) GB"

# Enable Remote Desktop Protocol (RDP)
Write-Host "Enabling RDP..."

# Enable RDP
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0

# Enable Network Level Authentication (more secure)
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 1

# Configure firewall to allow RDP
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Alternative firewall rule creation
New-NetFirewallRule -DisplayName "Remote Desktop" -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow

# Set RDP service to start automatically
Set-Service -Name TermService -StartupType Automatic

# Start the service
Start-Service TermService

Write-Host "RDP has been enabled successfully!"
Write-Host "RDP is accessible on port 3389"

# Display current RDP status
$rdpStatus = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections"
if ($rdpStatus.fDenyTSConnections -eq 0) {
    Write-Host "RDP Status: ENABLED"
} else {
    Write-Host "RDP Status: DISABLED"
}

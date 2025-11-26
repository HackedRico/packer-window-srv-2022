# Setup for Ansible compatibility
Write-Host "Setting up system for Ansible compatibility..."

# Install PowerShell modules required for Ansible
Write-Host "Installing required PowerShell modules..."

# Set PowerShell execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

# Install NuGet provider (required for PowerShell Gallery)
Install-PackageProvider -Name NuGet -Force -Confirm:$false

# Trust PowerShell Gallery
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

# Install required modules for Ansible
Install-Module -Name PowerShellGet -Force -AllowClobber
Install-Module -Name PackageManagement -Force -AllowClobber

# Configure WinRM for Ansible
Write-Host "Configuring WinRM for Ansible..."

# Set WinRM memory limits for Ansible (prevents memory errors)
Set-WSManInstance -ResourceURI winrm/config/winrs -ValueSet @{MaxMemoryPerShellMB="1024"}
Set-WSManInstance -ResourceURI winrm/config/winrs -ValueSet @{MaxShellsPerUser="50"}
Set-WSManInstance -ResourceURI winrm/config/winrs -ValueSet @{MaxConcurrentUsers="100"}

# Enable CredSSP for second hop authentication (if needed)
Enable-WSManCredSSP -Role Server -Force

# Disable complex passwords for easier automation (development only)
secedit /export /cfg c:\secpol.cfg
(gc C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg
rm -force c:\secpol.cfg -confirm:$false

# Disable Windows Updates automatic restart
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "UxOption" -Value 1 -ErrorAction SilentlyContinue

# Disable “new network detected” prompt logic
New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Network" -Name "NewNetworkWindowOff" -PropertyType DWord -Value 1 -Force

# Disable NLA active probing (faster boot)
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet" -Name "EnableActiveProbing" -Value 0 -PropertyType DWord -Force

# Configure network profile to Private (more permissive for automation)
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private

# Enable discovery services
Set-Service FDResPub  -StartupType Automatic
Set-Service SSDPSRV   -StartupType Automatic
Set-Service upnphost  -StartupType Automatic

Start-Service FDResPub
Start-Service SSDPSRV
Start-Service upnphost

Write-Host "Ansible setup completed successfully!"

# Display configuration summary
Write-Host "=== Configuration Summary ==="
Write-Host "PowerShell Execution Policy: $(Get-ExecutionPolicy)"
Write-Host "WinRM Service Status: $(Get-Service WinRM | Select-Object -ExpandProperty Status)"
Write-Host "Network Profile: $(Get-NetConnectionProfile | Select-Object -ExpandProperty NetworkCategory)"

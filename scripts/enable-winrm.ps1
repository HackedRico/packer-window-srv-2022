# Enable WinRM for HTTP and HTTPS connections
Write-Host "Enabling WinRM..."

# Enable WinRM service
Enable-PSRemoting -Force -SkipNetworkProfileCheck

# Configure WinRM for HTTP (port 5985)
Set-WSManInstance -ResourceURI winrm/config/service -ValueSet @{AllowUnencrypted="true"}
Set-WSManInstance -ResourceURI winrm/config/service/auth -ValueSet @{Basic="true"}
Set-WSManInstance -ResourceURI winrm/config/client -ValueSet @{AllowUnencrypted="true"}
Set-WSManInstance -ResourceURI winrm/config/client/auth -ValueSet @{Basic="true"}

# Create HTTP listener
Remove-WSManInstance -ResourceURI winrm/config/Listener -SelectorSet @{Address="*";Transport="HTTP"} -ErrorAction SilentlyContinue
New-WSManInstance -ResourceURI winrm/config/Listener -SelectorSet @{Address="*";Transport="HTTP"}

# Configure WinRM for HTTPS (port 5986)
# Create self-signed certificate for HTTPS
$cert = New-SelfSignedCertificate -DnsName "localhost" -CertStoreLocation "cert:\LocalMachine\My"

# Create HTTPS listener
Remove-WSManInstance -ResourceURI winrm/config/Listener -SelectorSet @{Address="*";Transport="HTTPS"} -ErrorAction SilentlyContinue
New-WSManInstance -ResourceURI winrm/config/Listener -SelectorSet @{Address="*";Transport="HTTPS"} -ValueSet @{CertificateThumbprint=$cert.Thumbprint}

# Set WinRM service to start automatically
Set-Service -Name WinRM -StartupType Automatic

# Configure firewall rules
New-NetFirewallRule -DisplayName "WinRM HTTP" -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow
New-NetFirewallRule -DisplayName "WinRM HTTPS" -Direction Inbound -Protocol TCP -LocalPort 5986 -Action Allow

# Restart WinRM service
Restart-Service WinRM

Write-Host "WinRM configuration completed successfully!"
Write-Host "HTTP listener on port 5985"
Write-Host "HTTPS listener on port 5986"

# Test WinRM
winrm enumerate winrm/config/listener

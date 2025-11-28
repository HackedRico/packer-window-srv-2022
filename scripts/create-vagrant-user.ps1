# Create vagrant user with admin privileges
Write-Host "Setting up vagrant user account..."

# Check if vagrant user already exists
$userExists = Get-LocalUser -Name "vagrant" -ErrorAction SilentlyContinue

if ($userExists) {
    Write-Host "Vagrant user already exists. Updating password and permissions..."
    # Update password
    $password = ConvertTo-SecureString "vagrant" -AsPlainText -Force
    Set-LocalUser -Name "vagrant" -Password $password
} else {
    Write-Host "Creating vagrant user..."
    # Create the vagrant user
    $password = ConvertTo-SecureString "vagrant" -AsPlainText -Force
    New-LocalUser -Name "vagrant" -Password $password -FullName "Vagrant" -Description "Vagrant User" -PasswordNeverExpires -UserMayNotChangePassword
}

# Add vagrant user to Administrators group
Write-Host "Adding vagrant user to Administrators group..."
Add-LocalGroupMember -Group "Administrators" -Member "vagrant" -ErrorAction SilentlyContinue

# Set password to never expire (via WMI for additional settings)
$user = [ADSI]"WinNT://./vagrant,user"
$user.UserFlags.value = $user.UserFlags.value -bor 0x10000  # ADS_UF_DONT_EXPIRE_PASSWD
$user.SetInfo()

# Enable auto-login for vagrant user
Write-Host "Configuring auto-login for vagrant user..."
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $RegPath -Name "AutoAdminLogon" -Value "1" -Type String
Set-ItemProperty -Path $RegPath -Name "DefaultUsername" -Value "vagrant" -Type String
Set-ItemProperty -Path $RegPath -Name "DefaultPassword" -Value "vagrant" -Type String

# Grant vagrant user rights for WinRM
Write-Host "Granting WinRM permissions to vagrant user..."
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'

# Add vagrant user to Remote Management Users group
Add-LocalGroupMember -Group "Remote Management Users" -Member "vagrant" -ErrorAction SilentlyContinue

Write-Host "Vagrant user setup completed successfully!"
Write-Host "Username: vagrant"
Write-Host "Password: vagrant"
Write-Host "Privileges: Administrator"

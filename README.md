# Windows Server 2022 Packer Template

This repository contains a Packer template for building a Windows Server 2022 VirtualBox image with minimal network configuration, designed for use with Terraform and Ansible, exported as a Vagrant Box.

All credentials, firewall rules, and security relaxations in this template support disposable development and lab environments; review and harden them for production use.

> This repository is published for reference and learning purposes.

## Features

- **VirtualBox Provider**: Uses VirtualBox for virtualization (requires x64/AMD64 system with hardware virtualization)
- **WinRM Support**: Configured for HTTP (port 5985) and HTTPS (port 5986) 
- **RDP Access**: Remote Desktop Protocol enabled on port 3389
- **Ansible Ready**: Pre-configured for Ansible automation without internet dependency
- **Minimal Network Config**: Clean NAT-only network setup without complex configurations
- **Vagrant Box Output**: Automatically creates a .box file for Terraform/Vagrant use
- **Automated Installation**: Fully unattended Windows installation using Autounattend.xml
- **HTTP Server**: Scripts served via Packer HTTP server (no floppy/CD issues)

## Prerequisites

1. **x64/AMD64 System**: VirtualBox cannot run 64-bit Windows on ARM (Mac M1/M2/M3) or without hardware virtualization
2. **Hardware Virtualization**: Intel VT-x or AMD-V must be enabled in BIOS/UEFI
3. **VirtualBox**: Version 6.1 or higher (with proper kernel modules loaded)
4. **Packer**: Version 1.8 or higher
5. **Disk Space**: At least 60GB free
6. **RAM**: At least 6GB available (4GB for VM + 2GB for host)
7. **Internet Connection**: Required for ISO download during first build (cached afterward)

## File Structure

```
├── windows2022.pkr.hcl                # Main Packer HCL2 template
├── Autounattend.xml                   # Windows unattended installation config
├── scripts/
│   ├── enable-winrm.ps1               # WinRM HTTP/HTTPS configuration
│   ├── enable-rdp.ps1                 # RDP configuration  
│   ├── install-guest-additions.ps1    # VirtualBox Guest Additions installer
│   ├── setup-ansible.ps1              # Ansible preparation (no internet required)
│   ├── cleanup.ps1                    # System cleanup & optimization
│   └── create-vagrant-user.ps1        # Vagrant user setup (optional)
├── builds/                            # Output directory for .box files
├── build.sh                           # Automated build script (optional)
└── VALIDATION.md                      # Pre-build validation checklist
```

## Usage

### 1. Verify Prerequisites

On your **x64/AMD64 Linux system** (Ubuntu, Debian, etc.), ensure hardware virtualization is enabled:

```bash
# Check CPU virtualization support
egrep -c '(vmx|svm)' /proc/cpuinfo
# Should return > 0

# Verify VirtualBox can see 64-bit capability
VBoxManage list hostinfo | grep -i "64-bit"

# Load VirtualBox kernel modules (if needed)
sudo /sbin/vboxconfig
```

⚠️ **Important**: This build **will not work** on:
- macOS ARM64 (M1/M2/M3) - VirtualBox doesn't support Windows on ARM Macs
- Systems without VT-x/AMD-V enabled in BIOS
- Systems without proper VirtualBox kernel modules loaded

### 2. Build the Image

```bash
# Initialize Packer plugins (first time only)
packer init windows2022.pkr.hcl

# Validate the template
packer validate windows2022.pkr.hcl

# Build the image (takes 35-55 minutes)
packer build windows2022.pkr.hcl
```

**Using a local ISO** (instead of downloading):
```bash
packer build -var "iso_url=/path/to/SERVER_EVAL_x64FRE_en-us.iso" windows2022.pkr.hcl
```

**Build process overview:**
1. Downloads Windows Server 2022 ISO (~5GB, cached for future builds)
2. Creates VirtualBox VM with Desktop Experience edition
3. Performs automated Windows installation via Autounattend.xml
4. Configures WinRM (HTTP/HTTPS) for Packer connectivity
5. Installs VirtualBox Guest Additions
6. Enables RDP and configures for Ansible
7. Cleans up and creates Vagrant box (~6-8GB compressed)

### 3. Add to Vagrant

```bash
# Add the built box to Vagrant
vagrant box add windows-server-2022 builds/windows-server-2022.box

# Verify the box was added
vagrant box list
```

### 4. Use with Terraform

Create a `main.tf` file:

```hcl
resource "vagrant_vm" "windows_server" {
  vagrantfile_dir = "."
  
  config = <<-EOF
    Vagrant.configure("2") do |config|
      config.vm.box = "windows-server-2022"
      config.vm.guest = :windows
      config.vm.communicator = "winrm"
      
      # Network configuration
      config.vm.network "private_network", type: "dhcp"
      
      # WinRM configuration
      config.winrm.username = "vagrant"
      config.winrm.password = "vagrant"
      config.winrm.port = 5985
      config.winrm.guest_port = 5985
      config.winrm.host = "127.0.0.1"
      
      # VirtualBox configuration
      config.vm.provider "virtualbox" do |vb|
        vb.memory = "4096"
        vb.cpus = 2
        vb.gui = false
      end
    end
  EOF
}
```

### 5. Use with Ansible

Example Ansible inventory:

```ini
[windows]
windows-server ansible_host=127.0.0.1 ansible_port=5985

[windows:vars]
ansible_user=vagrant
ansible_password=vagrant
ansible_connection=winrm
ansible_winrm_server_cert_validation=ignore
ansible_winrm_transport=basic
```

Example playbook:

```yaml
---
- name: Configure Windows Server
  hosts: windows
  tasks:
    - name: Ensure IIS is installed
      win_feature:
        name: IIS-WebServerRole
        state: present
        
    - name: Test WinRM connectivity
      win_ping:
```

## Configuration Details

### Default Credentials
- **Username**: vagrant
- **Password**: vagrant

### Network Ports
- **WinRM HTTP**: 5985
- **WinRM HTTPS**: 5986  
- **RDP**: 3389

### System Specifications
- **Disk Size**: 60 GB
- **Memory**: 4 GB
- **CPUs**: 2
- **Guest OS**: Windows Server 2022 Standard Evaluation

## Customization

### Modify VM Specifications

Edit `windows2022.pkr.hcl`:

```hcl
source "virtualbox-iso" "windows2022" {
  disk_size = 102400    # 100 GB
  memory    = 8192      # 8 GB
  cpus      = 4         # 4 CPUs
  # ... other settings
}
```

### Add Custom Software

Add provisioner steps in the build block:

```hcl
provisioner "powershell" {
  inline = [
    "choco install git -y",
    "choco install nodejs -y"
  ]
}
```

## Troubleshooting

### Build Issues

**1. Error: "64-bit application couldn't load" (0xc000035a)**
- **Cause**: Hardware virtualization (VT-x/AMD-V) not enabled or not available
- **Solution**: 
  - Enable VT-x/AMD-V in BIOS/UEFI settings
  - If running in a VM, enable nested virtualization on the host
  - Verify: `egrep -c '(vmx|svm)' /proc/cpuinfo` returns > 0

**2. Error: "Cleaning up floppy disk" / NS_ERROR_FAILURE (0x80004005)**
- **Cause**: VirtualBox floppy controller issues (resolved in current template)
- **Solution**: Template now uses CD for Autounattend.xml and HTTP server for scripts

**3. Windows Setup stuck at "Select operating system" screen**
- **Cause**: Autounattend.xml not detected or incorrect image index
- **Solution**: Template uses index 2 for "Desktop Experience" edition
- **Verify**: ISO contains "Windows Server 2022 SERVERSTANDARDEVAL (Desktop Experience)"

**4. WinRM Timeout / Packer can't connect**
- **Cause**: WinRM not enabled or firewall blocking connection
- **Solution**: 
  - Check Autounattend.xml is downloading and running enable-winrm.ps1
  - Verify HTTP server on port 8100 is accessible during build
  - Increase `winrm_timeout` to "8h" if needed

**5. VirtualBox kernel modules not loaded**
```bash
# Reconfigure VirtualBox
sudo /sbin/vboxconfig

# Load modules manually
sudo modprobe vboxdrv vboxnetadp vboxnetflt

# Add user to vboxusers group
sudo usermod -aG vboxusers $USER
```

**6. Build fails on macOS ARM64 (M1/M2/M3)**
- **Not Supported**: VirtualBox cannot run Windows on ARM Macs
- **Solution**: Use an x64/AMD64 Linux or Windows system instead

### Connection Issues After Build

**WinRM Connection Failed:**
- Verify firewall settings: `netsh advfirewall firewall show rule name="WinRM HTTP"`
- Check WinRM service: `Get-Service WinRM`
- Test from host: `curl http://localhost:5985/wsman`

**RDP Connection Failed:**
- Ensure RDP is enabled: Check System Properties → Remote Desktop
- Verify port forwarding in VirtualBox
- Test connection: `mstsc /v:localhost:3389`

### Performance Optimization

- **Faster Builds**: Increase memory to 8GB, CPUs to 4
- **SSD Storage**: Use SSD for VirtualBox VMs directory
- **Cached ISO**: Keep downloaded ISO in `packer_cache/` to avoid re-downloading
- **Headless Mode**: Set `headless = true` for background builds

## Technical Details

### Build Architecture
- **Autounattend.xml**: Provides Windows Setup with automated installation answers
- **HTTP Server**: Packer serves scripts on port 8100 (10.0.2.2:8100 from VM perspective)
- **WinRM Bootstrap**: Autounattend.xml downloads enable-winrm.ps1 via HTTP on first login
- **Provisioners**: All other scripts run via WinRM after initial connectivity established
- **Guest OS Type**: `Windows2022_64` explicitly tells VirtualBox this is 64-bit

### Network Configuration
- **NAT Network**: Default VirtualBox NAT (10.0.2.0/24)
- **Port Forwarding**: WinRM (5985, 5986), RDP (3389)
- **No Internet Required**: After ISO download, build works offline
- **Private Network**: Network profile set to Private for automation

### What Gets Configured
✅ vagrant/vagrant user with admin privileges  
✅ WinRM HTTP (5985) and HTTPS (5986) with self-signed cert  
✅ RDP enabled on port 3389  
✅ VirtualBox Guest Additions installed  
✅ PowerShell execution policy set to RemoteSigned  
✅ Password complexity disabled (dev environment)  
✅ Auto-login enabled for vagrant user  
✅ UAC disabled for automation  
✅ Windows Updates manual (no automatic restart)  
✅ Network discovery and file sharing enabled  
✅ System cleaned up (temp files, logs removed)  

## Security Notes

⚠️ **This template is designed for development/lab environments only**

- **Default credentials** (vagrant/vagrant) are hardcoded - change for any environment exposed to network
- **UAC disabled** - Re-enable for production: `Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1`
- **Password complexity disabled** - Re-enable via Group Policy or `secedit`
- **HTTP WinRM enabled** - Use HTTPS (port 5986) and validate certificates in production
- **Self-signed HTTPS cert** - Replace with proper CA-signed certificate
- **Auto-login enabled** - Disable before deploying outside local dev
- **Firewall rules permissive** - Review and restrict as needed
- **No antivirus/EDR** - Install appropriate security software for production

## License

This project is available under the [MIT License](LICENSE).

---

## Additional Resources

- [Packer Documentation](https://www.packer.io/docs)
- [VirtualBox Manual](https://www.virtualbox.org/manual/)
- [Ansible Windows Guide](https://docs.ansible.com/ansible/latest/user_guide/windows.html)

---

**Note**: This template creates a Windows Server 2022 **Evaluation** edition (180-day trial). For production use, ensure you have proper Microsoft licensing and use a licensed Windows Server ISO.

# Windows Server 2022 Packer Template

This repository contains a Packer template for building a Windows Server 2022 VirtualBox image with minimal network configuration, designed for use with Terraform and Ansible.

## Features

- **VirtualBox Provider**: Uses VirtualBox for virtualization
- **WinRM Support**: Configured for both HTTP (port 5985) and HTTPS (port 5986)
- **RDP Access**: Remote Desktop Protocol enabled on port 3389
- **Ansible Ready**: Pre-configured for Ansible automation
- **Minimal Network Config**: Clean network setup without complex configurations
- **Vagrant Box Output**: Automatically creates a .box file for Terraform use

## Prerequisites

1. **VirtualBox**: Install VirtualBox on your system
2. **Packer**: Install HashiCorp Packer
3. **Internet Connection**: For downloading the Windows Server 2022 ISO

## File Structure

```
├── windows2022.pkr.hcl          # Main Packer template
├── Autounattend.xml             # Windows unattended installation
├── scripts/
│   ├── enable-winrm.ps1         # WinRM configuration
│   ├── enable-rdp.ps1           # RDP configuration  
│   ├── setup-ansible.ps1        # Ansible preparation
│   └── cleanup.ps1              # System cleanup
└── builds/                      # Output directory for .box files
```

## Usage

### 1. Build the Image

```bash
# Initialize Packer (first time only)
packer init windows2022.pkr.hcl

# Validate the template
packer validate windows2022.pkr.hcl

# Build the image
packer build windows2022.pkr.hcl
```

### 2. Add to Vagrant

```bash
# Add the built box to Vagrant
vagrant box add windows-server-2022 builds/virtualbox-windows-server-2022.box

# Verify the box was added
vagrant box list
```

### 3. Use with Terraform

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

### 4. Use with Ansible

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

1. **ISO Download Fails**: Check internet connection and ISO URL
2. **VirtualBox Errors**: Ensure VirtualBox is properly installed
3. **WinRM Timeout**: Increase `winrm_timeout` in the template

### Connection Issues

1. **WinRM Connection Failed**: 
   - Verify firewall settings
   - Check WinRM service status
   - Confirm credentials

2. **RDP Connection Failed**:
   - Ensure RDP is enabled
   - Check firewall rules
   - Verify port forwarding

### Performance Optimization

- Increase VM memory for faster builds
- Use SSD storage for better I/O performance
- Enable hardware virtualization in BIOS

## Security Notes

- Default credentials are for development use only
- Change passwords in production environments
- Consider disabling unnecessary services
- Review firewall configurations

## License

This template is provided as-is for educational and development purposes.

---

**Note**: This creates a Windows Server 2022 Evaluation version. For production use, ensure you have proper licensing.

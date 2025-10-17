# Packer template for Windows Server 2022 on VirtualBox with WinRM (HTTP/HTTPS) and RDP
packer {
  required_plugins {
    virtualbox = {
      version = ">= 1.0.4"
      source  = "github.com/hashicorp/virtualbox"
    }
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
  }
}

variable "iso_url" {
  type    = string
  default = "https://software-static.download.prss.microsoft.com/sg/download/888969d5-f34g-4e03-ac9d-1f9786c66749/SERVER_EVAL_x64FRE_en-us.iso"
#  default = "images/windows-srv-2022.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:3e4fa6d8507b554856fc9ca6079cc402df11a8b79344871669f0251535255325"
  description = "SHA256 checksum of the ISO"
}

variable "vm_name" {
  type    = string
  default = "windows-server-2022"
}

source "virtualbox-iso" "windows2022" {
  iso_url              = var.iso_url
  iso_checksum         = var.iso_checksum
  communicator         = "winrm"
  winrm_username       = "vagrant"
  winrm_password       = "vagrant"
  winrm_timeout        = "6h"
  winrm_insecure       = true
  winrm_use_ssl        = false
  winrm_port           = 5985
  shutdown_command     = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
  guest_additions_mode = "attach"
  headless             = false
  vm_name              = var.vm_name
  disk_size            = 61440
  memory               = 4096
  cpus                 = 2
  boot_wait            = "2m"
  
  # Floppy files for automated installation
  floppy_files = [
    "Autounattend.xml",
    "scripts/enable-winrm.ps1",
    "scripts/enable-rdp.ps1",
    "scripts/setup-ansible.ps1",
    "scripts/cleanup.ps1"
  ]
  
  # VirtualBox settings for minimal network configuration
  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--natpf1", "winrm,tcp,,5985,,5985"],
    ["modifyvm", "{{.Name}}", "--natpf1", "winrm-ssl,tcp,,5986,,5986"],
    ["modifyvm", "{{.Name}}", "--natpf1", "rdp,tcp,,3389,,3389"]
  ]
}

build {
  sources = ["source.virtualbox-iso.windows2022"]

  # Enable WinRM HTTP and HTTPS
  provisioner "powershell" {
    script = "scripts/enable-winrm.ps1"
  }

  # Enable RDP
  provisioner "powershell" {
    script = "scripts/enable-rdp.ps1"
  }

  # Setup for Ansible
  provisioner "powershell" {
    script = "scripts/setup-ansible.ps1"
  }

  # Restart to apply changes
  provisioner "windows-restart" {
    restart_timeout = "5m"
  }

  # Final cleanup
  provisioner "powershell" {
    script = "scripts/cleanup.ps1"
  }

  # Create Vagrant box
  post-processor "vagrant" {
    compression_level = 9
    output           = "builds/{{.Provider}}-windows-server-2022.box"
   }
}

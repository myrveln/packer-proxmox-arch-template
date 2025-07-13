packer {
  required_plugins {
    proxmox-iso = {
      version = ">= 1.2.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "arch_vm" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  insecure_skip_tls_verify = true
  node                     = var.node_name
  os                       = "other"
  memory                   = var.vm_memory
  cores                    = var.vm_cores
  http_directory           = "http"
  boot_wait                = "10s"
  ssh_username             = var.ssh_username
  ssh_password             = var.ssh_password
  ssh_timeout              = "15m"
  template_description     = "Arch Linux generated on ${timestamp()}"
  template_name            = lower("arch-linux-${formatdate("YYYY-MMMM", timestamp())}")

  network_adapters {
    bridge = "vmbr0"
  }

  disks {
    type         = "scsi"
    disk_size    = var.disk_size
    storage_pool = "local-lvm"
  }

  boot_iso {
    type     = "scsi"
    iso_file = "local:iso/archlinux-x86_64.iso"
    unmount  = true
  }

  boot_command = [
    "<enter><wait10><wait10><wait10><wait10>",
    "curl -O 'http://{{ .HTTPIP }}:{{ .HTTPPort }}/install{,-chroot}.sh'<enter><wait>",
    "bash install.sh < install-chroot.sh && systemctl reboot<enter>"
  ]
}

build {
  sources = ["source.proxmox-iso.arch_vm"]
}

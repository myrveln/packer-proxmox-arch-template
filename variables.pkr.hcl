variable "proxmox_url" {
  type    = string
  default = "https://10.0.0.22:8006/api2/json"
}

variable "proxmox_username" {
  type    = string
  default = "root@pam"
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}

variable "node_name" {
  type    = string
  default = "proxmox"
}

variable "vm_memory" {
  type    = number
  default = 2048
}

variable "vm_cores" {
  type    = number
  default = 2
}

variable "ssh_username" {
  type    = string
  default = "kim"
}

variable "ssh_password" {
  type      = string
  sensitive = true
  default   = "template"
}

variable "disk_size" {
  type    = string
  default = "40G"
}

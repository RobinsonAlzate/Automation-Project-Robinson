variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "boot_diagnostics_uri" {
  type = string
}

variable "linux_vms" {
  type = map(object({
    zone = string
  }))
}

variable "vm_size" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "os_disk_type" {
  type = string
}

variable "image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
}

variable "network_watcher_version" {
  type = string
}

variable "azure_monitor_version" {
  type = string
}

variable "ip_configuration_name" {
  type    = string
  default = "internal"
}

variable "tags" {
  type = map(string)
}

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

variable "windows_vm_count" {
  type = number
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

variable "antimalware_version" {
  type    = string
  default = "1.3"
}

variable "tags" {
  type = map(string)
}

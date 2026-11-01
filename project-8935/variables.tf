variable "subscription_id" {
  type = string
}

variable "humber_id" {
  type = string
}

variable "location" {
  type    = string
  default = "centralus"
}

variable "tag_project" {
  type    = string
  default = "CCGC 5502 Terraform Project"
}

variable "tag_name" {
  type = string
}

variable "tag_expiration_date" {
  type    = string
  default = "2027-12-31"
}

variable "tag_environment" {
  type    = string
  default = "Learning"
}

variable "vnet_address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "subnet_address_prefixes" {
  type    = list(string)
  default = ["10.0.1.0/24"]
}

variable "nsg_rules" {
  type = list(object({
    name     = string
    priority = number
    port     = string
  }))
  default = [
    { name = "Allow-SSH", priority = 100, port = "22" },
    { name = "Allow-RDP", priority = 110, port = "3389" },
    { name = "Allow-WinRM", priority = 120, port = "5985" },
    { name = "Allow-HTTP", priority = 130, port = "80" }
  ]
}

variable "common_storage_suffix" {
  type    = string
  default = "commonsa"
}

variable "law_sku" {
  type    = string
  default = "PerGB2018"
}

variable "law_retention_days" {
  type    = number
  default = 30
}

variable "rsv_sku" {
  type    = string
  default = "Standard"
}

variable "storage_tier" {
  type    = string
  default = "Standard"
}

variable "storage_replication" {
  type    = string
  default = "LRS"
}

variable "vm_size" {
  type    = string
  default = "Standard_E2bds_v5"
}

variable "admin_username" {
  type    = string
  default = "azureadmin"
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "os_disk_type" {
  type    = string
  default = "Standard_LRS"
}

variable "linux_vms" {
  type = map(object({
    zone = string
  }))
  default = {
    "linux-vm1" = { zone = "1" }
    "linux-vm2" = { zone = "2" }
    "linux-vm3" = { zone = "3" }
  }
}

variable "windows_vm_count" {
  type    = number
  default = 1
}

variable "linux_image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_2-gen2"
    version   = "latest"
  }
}

variable "windows_image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }
}

variable "network_watcher_extension_version" {
  type    = string
  default = "1.0"
}

variable "azure_monitor_extension_version" {
  type    = string
  default = "1.0"
}

variable "data_disk_size_gb" {
  type    = number
  default = 10
}

variable "data_disk_type" {
  type    = string
  default = "Standard_LRS"
}

variable "lb_zones" {
  type    = list(string)
  default = ["1", "2", "3"]
}

variable "lb_frontend_port" {
  type    = number
  default = 80
}

variable "lb_backend_port" {
  type    = number
  default = 80
}

variable "lb_probe_port" {
  type    = number
  default = 80
}

variable "db_version" {
  type    = string
  default = "16"
}

variable "db_sku_name" {
  type    = string
  default = "B_Standard_B1ms"
}

variable "db_storage_mb" {
  type    = number
  default = 32768
}

variable "db_backup_retention_days" {
  type    = number
  default = 7
}

variable "db_admin_login" {
  type    = string
  default = "pgadmin"
}

variable "db_admin_password" {
  type      = string
  sensitive = true
}

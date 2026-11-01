variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_version" {
  type = string
}

variable "db_sku_name" {
  type = string
}

variable "db_storage_mb" {
  type = number
}

variable "backup_retention_days" {
  type = number
}

variable "admin_login" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "tags" {
  type = map(string)
}

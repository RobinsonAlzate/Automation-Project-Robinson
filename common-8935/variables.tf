variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "law_name" {
  type = string
}

variable "rsv_name" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "law_sku" {
  type = string
}

variable "law_retention_days" {
  type = number
}

variable "rsv_sku" {
  type = string
}

variable "storage_tier" {
  type = string
}

variable "storage_replication" {
  type = string
}

variable "tags" {
  type = map(string)
}

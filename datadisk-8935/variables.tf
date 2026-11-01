variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "disk_size_gb" {
  type = number
}

variable "disk_type" {
  type = string
}

variable "lun" {
  type    = number
  default = 0
}

variable "disk_targets" {
  type = map(object({
    vm_id = string
    zone  = optional(string)
  }))
}

variable "tags" {
  type = map(string)
}

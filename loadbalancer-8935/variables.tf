variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "lb_name" {
  type = string
}

variable "zones" {
  type = list(string)
}

variable "nic_ids" {
  type = map(string)
}

variable "ip_configuration_name" {
  type    = string
  default = "internal"
}

variable "frontend_port" {
  type = number
}

variable "backend_port" {
  type = number
}

variable "probe_port" {
  type = number
}

variable "tags" {
  type = map(string)
}

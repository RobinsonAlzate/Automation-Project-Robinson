output "hostnames" {
  value = { for k, vm in azurerm_linux_virtual_machine.vm : k => vm.computer_name }
}

output "fqdns" {
  value = { for k, p in azurerm_public_ip.pip : k => p.fqdn }
}

output "private_ips" {
  value = { for k, vm in azurerm_linux_virtual_machine.vm : k => vm.private_ip_address }
}

output "public_ips" {
  value = { for k, p in azurerm_public_ip.pip : k => p.ip_address }
}

output "vm_ids" {
  value = { for k, vm in azurerm_linux_virtual_machine.vm : k => vm.id }
}

output "nic_ids" {
  value = { for k, n in azurerm_network_interface.nic : k => n.id }
}

output "zones" {
  value = { for k, v in var.linux_vms : k => v.zone }
}

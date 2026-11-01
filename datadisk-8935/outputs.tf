output "disk_names" {
  value = [for d in azurerm_managed_disk.disk : d.name]
}

resource "azurerm_managed_disk" "disk" {
  for_each             = var.disk_targets
  name                 = "${var.name_prefix}-${each.key}-datadisk"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.disk_type
  create_option        = "Empty"
  disk_size_gb         = var.disk_size_gb
  zone                 = each.value.zone
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "attach" {
  for_each           = azurerm_managed_disk.disk
  managed_disk_id    = each.value.id
  virtual_machine_id = var.disk_targets[each.key].vm_id
  lun                = var.lun
  caching            = "ReadWrite"
}

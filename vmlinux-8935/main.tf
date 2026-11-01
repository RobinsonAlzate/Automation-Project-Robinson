resource "azurerm_public_ip" "pip" {
  for_each            = var.linux_vms
  name                = "${var.name_prefix}-${each.key}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [each.value.zone]
  domain_name_label   = lower("${each.key}-${var.name_prefix}")
  tags                = var.tags
}

resource "azurerm_network_interface" "nic" {
  for_each            = var.linux_vms
  name                = "${var.name_prefix}-${each.key}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = var.ip_configuration_name
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip[each.key].id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each                        = var.linux_vms
  name                            = "${var.name_prefix}-${each.key}"
  computer_name                   = each.key
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  zone                            = each.value.zone
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.nic[each.key].id]
  tags                            = var.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
  }

  source_image_reference {
    publisher = var.image.publisher
    offer     = var.image.offer
    sku       = var.image.sku
    version   = var.image.version
  }

  identity {
    type = "SystemAssigned"
  }

  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics_uri
  }
}

resource "azurerm_virtual_machine_extension" "network_watcher" {
  for_each                   = azurerm_linux_virtual_machine.vm
  name                       = "NetworkWatcherAgentLinux"
  virtual_machine_id         = each.value.id
  publisher                  = "Microsoft.Azure.NetworkWatcher"
  type                       = "NetworkWatcherAgentLinux"
  type_handler_version       = var.network_watcher_version
  auto_upgrade_minor_version = true
  tags                       = var.tags
}

resource "azurerm_virtual_machine_extension" "azure_monitor" {
  for_each                   = azurerm_linux_virtual_machine.vm
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = each.value.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = var.azure_monitor_version
  auto_upgrade_minor_version = true
  tags                       = var.tags

  depends_on = [azurerm_virtual_machine_extension.network_watcher]
}

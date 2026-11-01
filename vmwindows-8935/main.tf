resource "azurerm_availability_set" "aset" {
  name                         = "${var.name_prefix}-win-aset"
  location                     = var.location
  resource_group_name          = var.resource_group_name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  managed                      = true
  tags                         = var.tags
}

resource "azurerm_public_ip" "pip" {
  count               = var.windows_vm_count
  name                = "${var.name_prefix}-win-vm${count.index + 1}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = lower("win-vm${count.index + 1}-${var.name_prefix}")
  tags                = var.tags
}

resource "azurerm_network_interface" "nic" {
  count               = var.windows_vm_count
  name                = "${var.name_prefix}-win-vm${count.index + 1}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip[count.index].id
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  count                 = var.windows_vm_count
  name                  = "${var.name_prefix}-win-vm${count.index + 1}"
  computer_name         = "${var.name_prefix}win${count.index + 1}"
  location              = var.location
  resource_group_name   = var.resource_group_name
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  availability_set_id   = azurerm_availability_set.aset.id
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  tags                  = var.tags

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

  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics_uri
  }
}

resource "azurerm_virtual_machine_extension" "antimalware" {
  count                      = var.windows_vm_count
  name                       = "IaaSAntimalware"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm[count.index].id
  publisher                  = "Microsoft.Azure.Security"
  type                       = "IaaSAntimalware"
  type_handler_version       = var.antimalware_version
  auto_upgrade_minor_version = true
  tags                       = var.tags

  settings = jsonencode({
    AntimalwareEnabled        = true
    RealtimeProtectionEnabled = "true"
    ScheduledScanSettings = {
      isEnabled = "true"
      day       = "7"
      time      = "120"
      scanType  = "Quick"
    }
  })
}

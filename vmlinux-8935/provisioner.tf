# Null provisioner: SSH into every Linux VM and display its hostname
resource "null_resource" "hostname" {
  for_each = azurerm_linux_virtual_machine.vm

  triggers = {
    vm_id = each.value.id
  }

  connection {
    type     = "ssh"
    host     = azurerm_public_ip.pip[each.key].ip_address
    user     = var.admin_username
    password = var.admin_password
    timeout  = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo \"=== VM ${each.key} hostname is: $(hostname) ===\""
    ]
  }

  depends_on = [
    azurerm_virtual_machine_extension.network_watcher,
    azurerm_virtual_machine_extension.azure_monitor
  ]
}

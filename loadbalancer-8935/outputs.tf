output "lb_name" {
  value = azurerm_lb.lb.name
}

output "lb_public_ip" {
  value = azurerm_public_ip.lb_pip.ip_address
}

output "db_name" {
  value = azurerm_postgresql_flexible_server.pg.name
}

output "db_fqdn" {
  value = azurerm_postgresql_flexible_server.pg.fqdn
}

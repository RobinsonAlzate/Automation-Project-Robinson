resource "azurerm_postgresql_flexible_server" "pg" {
  name                          = var.db_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  version                       = var.db_version
  sku_name                      = var.db_sku_name
  storage_mb                    = var.db_storage_mb
  backup_retention_days         = var.backup_retention_days
  administrator_login           = var.admin_login
  administrator_password        = var.admin_password
  public_network_access_enabled = true
  tags                          = var.tags

  lifecycle {
    ignore_changes = [zone]
  }
}

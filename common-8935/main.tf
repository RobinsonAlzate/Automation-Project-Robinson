resource "azurerm_log_analytics_workspace" "law" {
  name                = var.law_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.law_sku
  retention_in_days   = var.law_retention_days
  tags                = var.tags
}

resource "azurerm_recovery_services_vault" "rsv" {
  name                = var.rsv_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.rsv_sku
  storage_mode_type   = "LocallyRedundant"
  tags                = var.tags
}

resource "azurerm_storage_account" "sa" {
  name                     = var.storage_account_name
  location                 = var.location
  resource_group_name      = var.resource_group_name
  account_tier             = var.storage_tier
  account_replication_type = var.storage_replication
  min_tls_version          = "TLS1_2"
  tags                     = var.tags
}

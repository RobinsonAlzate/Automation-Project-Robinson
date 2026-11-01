locals {
  prefix = var.humber_id

  common_tags = {
    Project        = var.tag_project
    Name           = var.tag_name
    ExpirationDate = var.tag_expiration_date
    Environment    = var.tag_environment
  }
}

module "rgroup" {
  source              = "../rgroup-8935"
  resource_group_name = "${local.prefix}-RG"
  location            = var.location
  tags                = local.common_tags
}

module "network" {
  source                  = "../network-8935"
  resource_group_name     = module.rgroup.resource_group_name
  location                = var.location
  vnet_name               = "${local.prefix}-VNET"
  subnet_name             = "${local.prefix}-SUBNET"
  nsg_name                = "${local.prefix}-NSG"
  vnet_address_space      = var.vnet_address_space
  subnet_address_prefixes = var.subnet_address_prefixes
  nsg_rules               = var.nsg_rules
  tags                    = local.common_tags
}

module "common" {
  source               = "../common-8935"
  resource_group_name  = module.rgroup.resource_group_name
  location             = var.location
  law_name             = "${local.prefix}-law"
  rsv_name             = "rsv-${local.prefix}"
  storage_account_name = lower("${local.prefix}${var.common_storage_suffix}")
  law_sku              = var.law_sku
  law_retention_days   = var.law_retention_days
  rsv_sku              = var.rsv_sku
  storage_tier         = var.storage_tier
  storage_replication  = var.storage_replication
  tags                 = local.common_tags
}

module "vmlinux" {
  source                  = "../vmlinux-8935"
  resource_group_name     = module.rgroup.resource_group_name
  location                = var.location
  name_prefix             = local.prefix
  subnet_id               = module.network.subnet_id
  boot_diagnostics_uri    = module.common.storage_blob_endpoint
  linux_vms               = var.linux_vms
  vm_size                 = var.vm_size
  admin_username          = var.admin_username
  admin_password          = var.admin_password
  os_disk_type            = var.os_disk_type
  image                   = var.linux_image
  network_watcher_version = var.network_watcher_extension_version
  azure_monitor_version   = var.azure_monitor_extension_version
  tags                    = local.common_tags
}

module "vmwindows" {
  source               = "../vmwindows-8935"
  resource_group_name  = module.rgroup.resource_group_name
  location             = var.location
  name_prefix          = local.prefix
  subnet_id            = module.network.subnet_id
  boot_diagnostics_uri = module.common.storage_blob_endpoint
  windows_vm_count     = var.windows_vm_count
  vm_size              = var.vm_size
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  os_disk_type         = var.os_disk_type
  image                = var.windows_image
  tags                 = local.common_tags
}

module "datadisk" {
  source              = "../datadisk-8935"
  resource_group_name = module.rgroup.resource_group_name
  location            = var.location
  name_prefix         = local.prefix
  disk_size_gb        = var.data_disk_size_gb
  disk_type           = var.data_disk_type

  disk_targets = merge(
    { for k, id in module.vmlinux.vm_ids : k => { vm_id = id, zone = module.vmlinux.zones[k] } },
    { for i, id in module.vmwindows.vm_ids : "win-vm${i + 1}" => { vm_id = id, zone = null } }
  )

  tags = local.common_tags
}

module "loadbalancer" {
  source              = "../loadbalancer-8935"
  resource_group_name = module.rgroup.resource_group_name
  location            = var.location
  lb_name             = "${local.prefix}-lb"
  zones               = var.lb_zones
  nic_ids             = module.vmlinux.nic_ids
  frontend_port       = var.lb_frontend_port
  backend_port        = var.lb_backend_port
  probe_port          = var.lb_probe_port
  tags                = local.common_tags
}

module "database" {
  source                = "../database-8935"
  resource_group_name   = module.rgroup.resource_group_name
  location              = var.location
  db_name               = "${local.prefix}-psql-ccgc5502"
  db_version            = var.db_version
  db_sku_name           = var.db_sku_name
  db_storage_mb         = var.db_storage_mb
  backup_retention_days = var.db_backup_retention_days
  admin_login           = var.db_admin_login
  admin_password        = var.db_admin_password
  tags                  = local.common_tags
}

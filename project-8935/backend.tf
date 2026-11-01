# Remote backend: Azure Storage Account created by scripts/backend-setup.sh
# (it lives in its own resource group, so terraform destroy never removes it)
terraform {
  backend "azurerm" {
    subscription_id      = "8c8941f9-9a8e-4c24-a1f8-60fc998da3c3"
    resource_group_name  = "rg-tfstate-8935"
    storage_account_name = "tfstate8935ccgc5502"
    container_name       = "tfstate"
    key                  = "ccgc5502.terraform.tfstate"
  }
}

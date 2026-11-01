# Filled in automatically by scripts/configure.sh
subscription_id = "8c8941f9-9a8e-4c24-a1f8-60fc998da3c3"
humber_id       = "8935"
tag_name        = "robinson.alzatte"
location        = "centralus"

vm_size          = "Standard_E2bds_v5"
db_sku_name      = "B_Standard_B1ms"
admin_username   = "azureadmin"
windows_vm_count = 1

# Learning-project passwords (change if you want). Needed so apply runs with zero prompts.
admin_password    = "Ccgc5502#Terraform2026"
db_admin_password = "Ccgc5502#Postgres2026"

# Linux image: Azure Monitor Agent (version 1.45+) refuses CentOS 8, so Ubuntu 22.04 LTS is used (supported by the agent).
linux_image = { publisher = "Canonical", offer = "0001-com-ubuntu-server-jammy", sku = "22_04-lts-gen2", version = "latest" }

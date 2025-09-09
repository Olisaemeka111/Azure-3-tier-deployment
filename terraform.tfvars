name_prefix      = "azure-3tier"
location         = "eastus"

vnet_cidr        = "10.0.0.0/16"
subnet_web_cidr  = "10.0.1.0/24"
subnet_biz_cidr  = "10.0.2.0/24"
subnet_db_cidr   = "10.0.3.0/24"
subnet_mgmt_cidr = "10.0.10.0/24"
subnet_appgw_cidr = "10.0.20.0/24"
subnet_bastion_cidr = "10.0.21.0/24"

admin_username  = "azureuser"
admin_ssh_key   = "" # If empty, module reads ~/.ssh/id_rsa.pub
admin_source_ip = "0.0.0.0/0"
admin_password  = "ChangeMe!Passw0rd#2025" # replace before applying

web_count = 2
biz_count = 2
db_count  = 2

vm_size_web  = "Standard_B2s"
vm_size_biz  = "Standard_B2s"
vm_size_db   = "Standard_B2s"
vm_size_jump = "Standard_B1ms"
vm_size_ad   = "Standard_B1ms"
vm_size_sql  = "Standard_B2s"
sql_vm_count = 2

domain_name   = "Centramax.com.uk"
dsrm_password = "BirdGrainSeed123!"


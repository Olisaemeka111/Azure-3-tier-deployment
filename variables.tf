variable "name_prefix" {
  description = "Prefix used for all resources"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vnet_cidr" {
  description = "CIDR for the VNet"
  type        = string
}

variable "subnet_web_cidr" {
  description = "Web subnet CIDR"
  type        = string
}

variable "subnet_biz_cidr" {
  description = "Business subnet CIDR"
  type        = string
}

variable "subnet_db_cidr" {
  description = "DB subnet CIDR"
  type        = string
}

variable "subnet_mgmt_cidr" {
  description = "Management subnet CIDR"
  type        = string
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
}

variable "admin_ssh_key" {
  description = "Public SSH key contents for admin user"
  type        = string
}

variable "admin_source_ip" {
  description = "CIDR or IP allowed to access management SSH"
  type        = string
}

variable "web_count" {
  description = "Number of instances in Web VMSS"
  type        = number
}

variable "biz_count" {
  description = "Number of instances in Business VMSS"
  type        = number
}

variable "db_count" {
  description = "Number of instances in DB VMSS (for demo only)"
  type        = number
}

variable "vm_size_web" {
  description = "VM size for Web tier"
  type        = string
}

variable "vm_size_biz" {
  description = "VM size for Business tier"
  type        = string
}

variable "vm_size_db" {
  description = "VM size for DB tier"
  type        = string
}

variable "vm_size_jump" {
  description = "VM size for Jumpbox"
  type        = string
}

variable "vm_size_ad" {
  description = "VM size for AD placeholder VM"
  type        = string
}

variable "admin_password" {
  description = "Admin password for Windows VMs (meets Azure complexity)."
  type        = string
  sensitive   = true
}

variable "sql_vm_count" {
  description = "Number of SQL Server VMs"
  type        = number
  default     = 2
}

variable "vm_size_sql" {
  description = "VM size for SQL Server VMs"
  type        = string
  default     = "Standard_D4s_v5"
}

variable "domain_name" {
  description = "Active Directory domain name (e.g., corp.contoso.com)"
  type        = string
}

variable "dsrm_password" {
  description = "Directory Services Restore Mode password for AD DS."
  type        = string
  sensitive   = true
}


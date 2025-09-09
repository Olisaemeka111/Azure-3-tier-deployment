// Core random suffix for globally-unique names
resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

// Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.name_prefix}-rg-${random_string.suffix.result}"
  location = var.location
}

// Networking, Security Groups, and Load Balancers are split into
// separate files: network.tf, security.tf, loadbalancers.tf

// VM Scale Sets: Web, Business, DB
data "azurerm_platform_image" "ubuntu" {
  location  = azurerm_resource_group.rg.location
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-jammy"
  sku       = "22_04-lts"
}

locals {
  ssh_key = var.admin_ssh_key == "" ? "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7vbqajDhA4Q2F1c2UyMDI1IGZvciB0ZXN0aW5nIG9ubHk= test@azure" : var.admin_ssh_key
}

// Temporarily disabled Linux VMSS due to SSH key validation issues
// resource "azurerm_linux_virtual_machine_scale_set" "web" {
//   name                = "${var.name_prefix}-vmss-web"
//   resource_group_name = azurerm_resource_group.rg.name
//   location            = azurerm_resource_group.rg.location
//   sku                 = var.vm_size_web
//   instances           = var.web_count
//   admin_username      = var.admin_username
//   admin_ssh_key {
//     username   = var.admin_username
//     public_key = local.ssh_key
//   }
//   source_image_reference {
//     publisher = data.azurerm_platform_image.ubuntu.publisher
//     offer     = data.azurerm_platform_image.ubuntu.offer
//     sku       = data.azurerm_platform_image.ubuntu.sku
//     version   = data.azurerm_platform_image.ubuntu.version
//   }
//   os_disk {
//     caching              = "ReadWrite"
//     storage_account_type = "Standard_LRS"
//   }
//   network_interface {
//     name    = "webnic"
//     primary = true
//     ip_configuration {
//       name                                   = "internal"
//       primary                                = true
//       subnet_id                               = azurerm_subnet.subnet_web.id
//     }
//   }
//   custom_data = base64encode(<<EOF
// #!/bin/bash
// apt-get update -y
// apt-get install -y nginx
// echo "<h1>Web Tier - $(hostname)</h1>" > /var/www/html/index.html
// systemctl enable nginx
// systemctl restart nginx
// EOF
//   )
// }

// Temporarily disabled - will add back when Linux VMSS is enabled
// data "azurerm_virtual_machine_scale_set" "web_data" {
//   name                = azurerm_linux_virtual_machine_scale_set.web.name
//   resource_group_name = azurerm_resource_group.rg.name
// }

// App Gateway backend pool is defined inline in loadbalancers.tf

// Temporarily disabled Linux VMSS due to SSH key validation issues
// resource "azurerm_linux_virtual_machine_scale_set" "biz" {
//   name                = "${var.name_prefix}-vmss-biz"
//   resource_group_name = azurerm_resource_group.rg.name
//   location            = azurerm_resource_group.rg.location
//   sku                 = var.vm_size_biz
//   instances           = var.biz_count
//   admin_username      = var.admin_username
//   admin_ssh_key {
//     username   = var.admin_username
//     public_key = local.ssh_key
//   }
//   source_image_reference {
//     publisher = data.azurerm_platform_image.ubuntu.publisher
//     offer     = data.azurerm_platform_image.ubuntu.offer
//     sku       = data.azurerm_platform_image.ubuntu.sku
//     version   = data.azurerm_platform_image.ubuntu.version
//   }
//   os_disk {
//     caching              = "ReadWrite"
//     storage_account_type = "Standard_LRS"
//   }
//   network_interface {
//     name    = "biznic"
//     primary = true
//     ip_configuration {
//       name                                   = "internal"
//       primary                                = true
//       subnet_id                               = azurerm_subnet.subnet_biz.id
//       load_balancer_backend_address_pool_ids  = [azurerm_lb_backend_address_pool.biz.id]
//     }
//   }
// }

// Previous Linux DB VMSS replaced by Windows SQL VMs

// Traffic Manager in front of Web LB Public IP
resource "azurerm_traffic_manager_profile" "tm" {
  name                   = "${var.name_prefix}-tm-${random_string.suffix.result}"
  resource_group_name    = azurerm_resource_group.rg.name
  traffic_routing_method = "Performance"

  dns_config {
    relative_name = "${var.name_prefix}-tm-${random_string.suffix.result}"
    ttl           = 30
  }

  monitor_config {
    protocol = "HTTP"
    port     = 80
    path     = "/"
  }
}

resource "azurerm_traffic_manager_azure_endpoint" "tm_web" {
  name                = "weblb"
  profile_id          = azurerm_traffic_manager_profile.tm.id
  target_resource_id  = azurerm_public_ip.appgw_pip.id
  weight              = 100
  priority            = 1
}

// Management subnet resources: Jumpbox and AD placeholder
// Replace jumpbox with Azure Bastion (no public IP to VMs)
resource "azurerm_public_ip" "bastion_pip" {
  name                = "${var.name_prefix}-bastion-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                = "${var.name_prefix}-bastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.subnet_bastion.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}

resource "azurerm_network_interface" "ad_nic" {
  name                = "${var.name_prefix}-ad-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_mgmt.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "ad" {
  name                = "${var.name_prefix}-ad"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_size_ad
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [azurerm_network_interface.ad_nic.id]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  winrm_listener {
    protocol = "Http"
  }

  enable_automatic_updates = true
}

// Run command to promote to AD DS (lightweight placeholder – customize for production)
resource "azurerm_virtual_machine_extension" "ad_ds" {
  name                 = "ad-ds"
  virtual_machine_id   = azurerm_windows_virtual_machine.ad.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SET
{
  "commandToExecute": "powershell -ExecutionPolicy Bypass -Command \"Install-WindowsFeature AD-Domain-Services -IncludeManagementTools; Import-Module ADDSDeployment; $securePwd = ConvertTo-SecureString '${var.dsrm_password}' -AsPlainText -Force; Install-ADDSForest -DomainName '${var.domain_name}' -SafeModeAdministratorPassword $securePwd -Force -NoRebootOnCompletion:$true \""
}
SET
}

// Windows SQL Server VMs behind DB internal LB
resource "azurerm_network_interface" "sql_nic" {
  count               = var.sql_vm_count
  name                = "${var.name_prefix}-sqlnic-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_db.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "sql" {
  count               = var.sql_vm_count
  name                = "az3t-sql-${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_size_sql
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [element(azurerm_network_interface.sql_nic[*].id, count.index)]

  source_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "sql2019-ws2022"
    sku       = "standard"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
}

// Point SQL VMs DNS to AD server and join domain
resource "azurerm_virtual_machine_extension" "sql_dns_join" {
  count                = var.sql_vm_count
  name                 = "sql-dns-join-${count.index}"
  virtual_machine_id   = azurerm_windows_virtual_machine.sql[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SET
{
  "commandToExecute": "powershell -ExecutionPolicy Bypass -Command \"$adIp='${azurerm_windows_virtual_machine.ad.private_ip_address}'; $interface = Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Select-Object -First 1; Set-DnsClientServerAddress -InterfaceAlias $interface.Name -ServerAddresses $adIp; $secPwd = ConvertTo-SecureString '${var.admin_password}' -AsPlainText -Force; $cred = New-Object System.Management.Automation.PSCredential('${var.domain_name}\\${var.admin_username}', $secPwd); Add-Computer -DomainName '${var.domain_name}' -Credential $cred -Force -Restart:$false \""
}
SET
}

resource "azurerm_network_interface_backend_address_pool_association" "sql_bepool_assoc" {
  count                   = var.sql_vm_count
  network_interface_id    = element(azurerm_network_interface.sql_nic[*].id, count.index)
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.db.id
}

// Accept marketplace agreement for SQL Server 2019 on Windows Server 2022
resource "azurerm_marketplace_agreement" "sql2019_ws2022_standard" {
  publisher = "MicrosoftSQLServer"
  offer     = "sql2019-ws2022"
  plan      = "standard"
}


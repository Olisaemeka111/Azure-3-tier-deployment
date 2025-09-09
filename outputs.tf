output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "appgw_public_ip" {
  value = azurerm_public_ip.appgw_pip.ip_address
}

output "traffic_manager_fqdn" {
  value = azurerm_traffic_manager_profile.tm.fqdn
}

output "bastion_public_ip" {
  value = azurerm_public_ip.bastion_pip.ip_address
}


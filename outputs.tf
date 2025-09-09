output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "web_lb_public_ip" {
  value = azurerm_public_ip.web_lb_pip.ip_address
}

output "traffic_manager_fqdn" {
  value = azurerm_traffic_manager_profile.tm.fqdn
}

output "jumpbox_public_ip" {
  value = azurerm_public_ip.jump_pip.ip_address
}


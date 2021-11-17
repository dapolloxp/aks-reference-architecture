
output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "vnet_address_space" {
  value = azurerm_virtual_network.vnet.address_space
}

output "vnet_subnets" {
  value = azurerm_virtual_network.vnet.subnet
}
/*
output "default_subnet_id" {
  value = azurerm_subnet.vnet.id
}

output "default_subnet_name" {
  value = azurerm_subnet.vnet.name
}


output "vnet_rg" {
  value = azurerm_subnet.vnet.resource_group_name
}

*/
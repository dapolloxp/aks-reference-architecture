resource "azurerm_subnet" "vnet" {
  name                                           = var.subnet_name
  resource_group_name                            = var.resource_group_name
  virtual_network_name                           = var.vnet_name
  address_prefixes                               = var.subnet_prefixes
  enforce_private_link_endpoint_network_policies = true

}

data "azurerm_virtual_network" "vnet_name" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
  depends_on = [
    azurerm_subnet.vnet
  ]

}


resource "azurerm_route_table" "spoke_rt" {
  #count = length(data.azurerm_virtual_network.vnetexample.subnets)

  name = "${azurerm_subnet.vnet.name}_default_route_table"

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
  resource_group_name = azurerm_subnet.vnet.resource_group_name
  location            = data.azurerm_virtual_network.vnet_name.location

  route {
    name                   = "default_egress"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.azure_fw_ip
  }

}

resource "azurerm_subnet_route_table_association" "route_assoc" {
  subnet_id      = azurerm_subnet.vnet.id
  route_table_id = azurerm_route_table.spoke_rt.id

}
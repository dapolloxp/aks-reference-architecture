# Jump host TF Module
# Subnet for jump_host
resource "azurerm_subnet" "jump_host" {
    name                        = "snet-jumphost"
    resource_group_name         = var.resource_group_name
    virtual_network_name        = var.jump_host_vnet_name
    address_prefixes            = [var.jump_host_addr_prefix]
}

# NIC for jump_host

resource "azurerm_network_interface" "jump_host" { 
    name                              = "nic-${var.jump_host_name}"
    location                          = var.location
    resource_group_name               = var.resource_group_name
    
    ip_configuration { 
        name                          = "configuration"
        subnet_id                     = azurerm_subnet.jump_host.id 
        private_ip_address_allocation = "Static"
        private_ip_address            = var.jump_host_private_ip_addr
    }
}

# NSG for jump_host Subnet

resource "azurerm_network_security_group" "jump_host" { 
    name                        = "nsg-jumphost-subnet"
    location                    = var.location
    resource_group_name         = var.resource_group_name
}

resource "azurerm_subnet_network_security_group_association" "jumphost_nsg_assoc" {
  subnet_id                 = azurerm_subnet.jump_host.id 
  network_security_group_id = azurerm_network_security_group.jump_host.id
}

#Route Table for Jump Host
resource "azurerm_route_table" "jumphost_rt" {
  
  name = "rt-${azurerm_subnet.jump_host.name}"

  lifecycle {
    ignore_changes = [      
      tags
    ]
  }
  resource_group_name                 = azurerm_subnet.jump_host.resource_group_name
  location                            = var.location

  route {
    name                        = "default_egress"
    address_prefix              = "0.0.0.0/0" 
    next_hop_type               = "VirtualAppliance"
    next_hop_in_ip_address      =  var.azure_fw_ip
  }

}

resource "azurerm_subnet_route_table_association" "route_assoc" {
  subnet_id      = azurerm_subnet.jump_host.id
  route_table_id = azurerm_route_table.jumphost_rt.id
  
}



# Virtual Machine for jump_host 

resource "azurerm_windows_virtual_machine" "jump_host" {
  name                  = var.jump_host_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [
        azurerm_network_interface.jump_host.id
    ]
  size               = var.jump_host_vm_size
 
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
 
  os_disk {
    name              = "osdisk-${var.jump_host_name}"
    caching           = "ReadWrite"  
    storage_account_type = "Standard_LRS"
  }
 
  identity {
    type = "SystemAssigned"
  }
  computer_name      = var.jump_host_name
  admin_username     = var.jump_host_admin_username
  admin_password     = var.jump_host_password
  
  provision_vm_agent = true
 
  timeouts {
      create = "60m"
      delete = "2h"
  }
}

 data "azurerm_client_config" "current" {}
 data "azurerm_subscription" "sub" {
}

 
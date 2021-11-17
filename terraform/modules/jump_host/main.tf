# Jump host TF Module
# Subnet for jump_host
resource "azurerm_subnet" "jump_host" {
  name                 = "jumphost-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.jump_host_vnet_name
  address_prefixes     = [var.jump_host_addr_prefix]
}

# NIC for jump_host

resource "azurerm_network_interface" "jump_host" {
  name                = "${var.jump_host_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "configuration"
    subnet_id                     = azurerm_subnet.jump_host.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.jump_host_private_ip_addr
  }
}

# NSG for jump_host Subnet

resource "azurerm_network_security_group" "jump_host" {
  name                = "jumphost-subnet-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet_network_security_group_association" "jumphost_nsg_assoc" {
  subnet_id                 = azurerm_subnet.jump_host.id
  network_security_group_id = azurerm_network_security_group.jump_host.id
}

# Virtual Machine for jump_host 

resource "azurerm_linux_virtual_machine" "jump_host" {
  name                = var.jump_host_name
  location            = var.location
  resource_group_name = var.resource_group_name
  network_interface_ids = [
    azurerm_network_interface.jump_host.id
  ]
  size = var.jump_host_vm_size
  /*
  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
 }*/
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                 = "${var.jump_host_name}-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  identity {
    type = "SystemAssigned"
  }
  computer_name                   = var.jump_host_name
  admin_username                  = var.jump_host_admin_username
  admin_password                  = var.jump_host_password
  disable_password_authentication = false


  provision_vm_agent = true



  timeouts {
    create = "60m"
    delete = "2h"
  }
}

locals {
  # I
  kv_name = element(split("/", var.key_vault_id), length(split("/", var.key_vault_id)) - 1)
}
// element(split("/", key_vault_id),length(split("/", key_vault_id))-1)
resource "azurerm_virtual_machine_extension" "Installdependancies" {
  name                 = "${var.jump_host_name}_vm_extension"
  virtual_machine_id   = azurerm_linux_virtual_machine.jump_host.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  # "script":"${filebase64("${path.module}/tools_install.sh '${local.kv_name}'")}"
  protected_settings = <<PROTECTED_SETTINGS
    {
      "commandToExecute": "./tools_install.sh ${local.kv_name}"
    }
    PROTECTED_SETTINGS
  settings           = <<SETTINGS
    {
        
        "fileUris": ["https://raw.githubusercontent.com/dapolloxp/aks-reference-architecture/main/terraform/modules/jump_host/tools_install.sh"]  
    }
    SETTINGS
  depends_on = [
    azurerm_key_vault_access_policy.vm_key_access
  ]

}


data "azurerm_client_config" "current" {}
data "azurerm_subscription" "sub" {
}

resource "azurerm_role_assignment" "vm_reader" {
  scope = data.azurerm_subscription.sub.id
  //scope                  = tostring(join("",[data.azurerm_subscription.sub.id, "/ResourceGroups/",var.kv_rg]))
  role_definition_name = "Reader"
  principal_id         = azurerm_linux_virtual_machine.jump_host.identity[0].principal_id
  depends_on = [
    azurerm_linux_virtual_machine.jump_host,
    azurerm_key_vault_access_policy.vm_key_access
  ]
}

resource "azurerm_key_vault_access_policy" "vm_key_access" {
  key_vault_id = var.key_vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_virtual_machine.jump_host.identity[0].principal_id
  //object_id = data.azurerm_client_config.current.object_id
  //application_id = azurerm_linux_virtual_machine.jump_host.identity[0].principal_id
  key_permissions = [
    "Get",
    "Create"
  ]

  secret_permissions = [
    "Get",
    "Set"
  ]
  depends_on = [
    azurerm_linux_virtual_machine.jump_host
  ]
}
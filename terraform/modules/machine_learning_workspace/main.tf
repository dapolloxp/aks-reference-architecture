# Network Security Groups

resource "azurerm_network_security_group" "nsg-training" {
  name                = "nsg-training"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "BatchNodeManagement"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "29876-29877"
    source_address_prefix      = "BatchNodeManagement"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AzureMachineLearning"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "44224"
    source_address_prefix      = "AzureMachineLearning"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg-training-link" {
  subnet_id                 = var.snet_training_id
  network_security_group_id = azurerm_network_security_group.nsg-training.id
}

resource "azurerm_network_security_group" "nsg-aks" {
  name                = "nsg-aks"
  location            = var.location
  resource_group_name = var.resource_group_name


}

resource "azurerm_subnet_network_security_group_association" "nsg-aks-link" {
  subnet_id                 = var.snet_aks_id
  network_security_group_id = azurerm_network_security_group.nsg-aks.id
}

# Machine Learning workspace
resource "azurerm_machine_learning_workspace" "machine_learning_workspace" {
  name                    = var.mlw_name
  location                = var.location
  resource_group_name     = var.resource_group_name
  application_insights_id = var.application_insights_id
  key_vault_id            = var.key_vault_id
  storage_account_id      = var.storage_account_id
  container_registry_id   = var.container_registry_id

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_private_endpoint" "machine-learning-workspace-endpoint" {
  name                = "mlw-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.snet_training_id

  private_service_connection {
    name                           = "mlw-private-link-connection"
    private_connection_resource_id = azurerm_machine_learning_workspace.machine_learning_workspace.id
    is_manual_connection           = false
    subresource_names              = ["amlworkspace"]
  }

  private_dns_zone_group {
    name                          = "mlw-dns-zone-group"
    private_dns_zone_ids          = [ var.machine_learning_workspace_notebooks_zone_id, var.machine_learning_workspace_api_zone_id ]
  }     
}
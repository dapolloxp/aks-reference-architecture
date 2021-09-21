

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
  subnet_id           = var.subnet_id

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
# create SB MI and keda MI

resource "azurerm_user_assigned_identity" "keda_identity" {
  name                = "keda-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_user_assigned_identity" "sb_processor_identity" {
  name                = "sb-processor-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_role_assignment" "keda_sb_role_assignment" {
  scope                = var.sb_id
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = azurerm_user_assigned_identity.keda_identity.principal_id
}

resource "azurerm_role_assignment" "sb_processor_role_assignment" {
  scope                = var.sb_id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = azurerm_user_assigned_identity.sb_processor_identity.principal_id
}


resource "azurerm_servicebus_namespace" "sb_premium" {
  name                = var.sb-name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Premium"
  capacity            = 1
}

resource "azurerm_servicebus_queue" "orders_queue" {
  name                = "orders"
  resource_group_name = var.resource_group_name
  namespace_name      = azurerm_servicebus_namespace.sb_premium.name

  enable_partitioning = true
}
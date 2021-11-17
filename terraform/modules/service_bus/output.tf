output "service_bus_id" {
  description = "SB ID"
  value       = azurerm_servicebus_namespace.sb_premium.id
}
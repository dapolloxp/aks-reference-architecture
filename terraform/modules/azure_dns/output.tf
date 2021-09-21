output "acr_private_zone_id" {
    value = azurerm_private_dns_zone.acr_zone.id
}

output "kv_private_zone_id" {
    value = azurerm_private_dns_zone.keyvault_zone.id
}

output "kv_private_zone_name" {
    value = azurerm_private_dns_zone.keyvault_zone.name
}

output "storage_account_blob_private_zone_id" {
    value = azurerm_private_dns_zone.storage_account_blob_zone.id
}
output "storage_account_file_private_zone_id" {
    value = azurerm_private_dns_zone.storage_account_file_zone.id
}

output "machine_learning_workspace_notebooks_zone_id" {
    value = azurerm_private_dns_zone.machine_learning_workspace_notebooks_zone.id
}

output "machine_learning_workspace_api_zone_id" {
    value = azurerm_private_dns_zone.machine_learning_workspace_api_zone.id
}
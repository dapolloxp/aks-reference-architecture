output "kv_private_zone_name" {
  value = azurerm_key_vault.vault.name
}

output "kv_key_zone_id" {
  value = azurerm_key_vault.vault.id
}
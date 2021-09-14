resource "azurerm_private_dns_zone" "keyvault_zone" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv-hub-link" {
  name                  = "keyvault-zone-hub-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault_zone.name
  virtual_network_id    = var.hub_virtual_network_id
}

resource "azurerm_private_dns_zone" "acr_zone" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr-hub-link" {
  name                  = "acr-zone-hub-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr_zone.name
  virtual_network_id    = var.hub_virtual_network_id
}

resource "azurerm_private_dns_zone" "storage_account_blob_zone" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage-account-blob-hub-link" {
  name                  = "storage-account-blob-zone-hub-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_account_blob_zone.name
  virtual_network_id    = var.hub_virtual_network_id
}


resource "azurerm_private_dns_zone" "storage_account_file_zone" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage-account-file-hub-link" {
  name                  = "storage-account-file-zone-hub-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_account_file_zone.name
  virtual_network_id    = var.hub_virtual_network_id
}
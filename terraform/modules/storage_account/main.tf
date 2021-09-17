resource "azurerm_storage_account" "storage_account" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind              = "StorageV2"

  network_rules {
    default_action  = "Deny"
    bypass          = ["AzureServices"]
    
  }
}


resource "azurerm_private_endpoint" "storage_account_blob_pe" {
  name                = "st-blob-endpoint"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  subnet_id                = var.subnet_id
  lifecycle {
    ignore_changes = [
      
      tags
    ]
  }
  private_service_connection {
    name                           = "storage-account-private-link-connection"
    private_connection_resource_id = azurerm_storage_account.storage_account.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                          = element(split("/", var.storage_account_blob_private_zone_id),length(split("/", var.storage_account_blob_private_zone_id))-1)
    private_dns_zone_ids          = [ var.storage_account_blob_private_zone_id ]
  } 
}


resource "azurerm_private_endpoint" "storage_account_file_pe" {
  name                = "st-file-endpoint"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  subnet_id                = var.subnet_id
  lifecycle {
    ignore_changes = [
      
      tags
    ]
  }
  private_service_connection {
    name                           = "storage-account-private-link-connection"
    private_connection_resource_id = azurerm_storage_account.storage_account.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                          = element(split("/", var.storage_account_file_private_zone_id),length(split("/", var.storage_account_file_private_zone_id))-1)
    private_dns_zone_ids          = [ var.storage_account_file_private_zone_id ]
  } 
}
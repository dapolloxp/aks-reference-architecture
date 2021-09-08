resource "azurerm_container_registry" "acr" {
  name                     = var.acr_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  sku                      = "Premium"
  admin_enabled            = false
  network_rule_set         {
    default_action          = "Deny"
  }
  public_network_access_enabled = false
  lifecycle {
    ignore_changes = [
      
      tags
    ]
  }
}


resource "azurerm_private_endpoint" "acr_pe" {
  name                = "acr-pe"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  subnet_id                = var.subnet_id
  lifecycle {
    ignore_changes = [
      
      tags
    ]
  }
  private_service_connection {
    name                           = "kv-private-link-connection"
    private_connection_resource_id = azurerm_container_registry.acr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                          = element(split("/", var.acr_private_zone_id),length(split("/", var.acr_private_zone_id))-1)
    private_dns_zone_ids          = [ var.acr_private_zone_id ]
  } 
}
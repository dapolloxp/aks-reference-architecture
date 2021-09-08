# Azure Firewall TF Module
resource "azurerm_subnet" "azure_firewall" {
    name                        = "AzureFirewallSubnet"
    resource_group_name         = var.resource_group_name
    virtual_network_name        = var.azurefw_vnet_name
    address_prefixes            = [var.azurefw_addr_prefix]
} 

resource "azurerm_public_ip" "azure_firewall" {
    name                        = "azure-firewall-ip"
    location                    = var.location
    resource_group_name         = var.resource_group_name
    allocation_method           = "Static"
    sku                         = "Standard"
}

resource "azurerm_firewall_policy" "base_policy" {
  name                = "base_policy"
  resource_group_name = var.resource_group_name
  location            = var.location
  dns {
    proxy_enabled = true
  }
}


resource "azurerm_firewall" "azure_firewall_instance" { 
    name                        = var.azurefw_name
    location                    = var.location
    resource_group_name         = var.resource_group_name
    
    dns_servers                 = [ 
        "168.63.129.16"
    ]
    ip_configuration {
        name                    = "configuration"
        subnet_id               = azurerm_subnet.azure_firewall.id 
        public_ip_address_id    = azurerm_public_ip.azure_firewall.id
    }

    timeouts {
      create = "60m"
      delete = "2h"
  }
  depends_on = [ azurerm_public_ip.azure_firewall ]
}

resource "azurerm_monitor_diagnostic_setting" "azfw_diag" {
  name                        = "monitoring"
  target_resource_id          = azurerm_firewall.azure_firewall_instance.id
  log_analytics_workspace_id  = var.sc_law_id

  log {
    category = "AzureFirewallApplicationRule"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "AzureFirewallNetworkRule"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "AzureFirewallDnsProxy"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }

}

resource "azurerm_firewall_policy_rule_collection_group" "aks_rule_collection" {
  name               = "aks-fwpolicy-rcg"
  firewall_policy_id = azurerm_firewall_policy.base_policy.id
  priority           = 100
  application_rule_collection {
    name     = "aks_app_rule_collection"
    priority = 200
    action   = "Allow"

    rule {
      name = "aks_service_tag"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_aks_spk_ip_g_id]      
      destination_fqdn_tags = ["AzureKubernetesService"]
    }

    rule {
      name = "ubuntu_libraries"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_aks_spk_ip_g_id]      
      destination_fqdns = ["api.snapcraft.io","motd.ubuntu.com",]
    }

    rule {
      name = "microsoft_crls"
      protocols {
        type = "Http"
        port = 80
      }
      source_ip_groups = [var.region1_aks_spk_ip_g_id]      
      destination_fqdns = ["crl.microsoft.com",
                          "mscrl.microsoft.com",  
                          "crl3.digicert.com",
                          "ocsp.digicert.com"]
    }

    rule {
      name = "github_rules"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_aks_spk_ip_g_id]      
      destination_fqdns = ["github.com"]
    }

    rule {
      name = "microsoft_metrics_rules"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_aks_spk_ip_g_id]      
      destination_fqdns = ["*.prod.microsoftmetrics.com"]
    }

    rule {
      name = "aks_acs_rules"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_aks_spk_ip_g_id]      
      destination_fqdns = ["acs-mirror.azureedge.net",
                           "*.docker.io",
                           "production.cloudflare.docker.com",
                          "*.azurecr.io"]
    }

    rule {
      name = "microsoft_login_rules"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_aks_spk_ip_g_id]      
      destination_fqdns = ["login.microsoftonline.com"]
    }
  }

  network_rule_collection {
    name     = "aks_network_rule_collection"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "aks_global_network_rule"
      protocols             = ["TCP"]
      source_ip_groups = [var.region1_aks_spk_ip_g_id]      
      destination_fqdns = ["AzureCloud"]
      destination_ports     = ["443", "9000"]
    }

    rule {
      name                  = "aks_ntp_network_rule"
      protocols             = ["UDP"]
      source_ip_groups = [var.region1_aks_spk_ip_g_id]      
      destination_addresses = ["*"]
      destination_ports     = ["123"]
    }
  }
}

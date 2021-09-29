# Azure Firewall TF Module
resource "azurerm_subnet" "azure_firewall" {
    name                        = "AzureFirewallSubnet"
    resource_group_name         = var.resource_group_name
    virtual_network_name        = var.azurefw_vnet_name
    address_prefixes            = [var.azurefw_addr_prefix]
    
} 

resource "azurerm_public_ip" "azure_firewall" {
    name                        = "pip-azfw"
    location                    = var.location
    resource_group_name         = var.resource_group_name
    allocation_method           = "Static"
    sku                         = "Standard"
}

resource "azurerm_firewall_policy" "base_policy" {
  name                = "afwp-base"
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
    firewall_policy_id          = azurerm_firewall_policy.base_policy.id   

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
  name                        = var.azfw_diag_name
  target_resource_id          = azurerm_firewall.azure_firewall_instance.id
  log_analytics_workspace_id  = var.law_id

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

resource "azurerm_firewall_policy_rule_collection_group" "hub_to_spoke_rule_collection" {
  name               = "hub-to-spoke-afwpolicy-rcg"
  firewall_policy_id = azurerm_firewall_policy.base_policy.id
  priority           = 110

  network_rule_collection {
    name     = "hub-to-spoke-network-rule-collection"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "hub-to-spoke-global-network-rule"
      protocols             = ["Any"]
      source_ip_groups      = [var.region1_mlw_spk_ip_g_id]      
      destination_ip_groups = [var.region1_hub_ip_g_id]
      destination_ports     = ["*"]
    }
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "aks_rule_collection" {
  name               = "aks-afwpolicy-rcg"
  firewall_policy_id = azurerm_firewall_policy.base_policy.id
  priority           = 200
  application_rule_collection {
    name     = "aks-app-rule-collection"
    priority = 200
    action   = "Allow"

    rule {
      name = "aks-service-tag"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdn_tags = ["AzureKubernetesService"]
    }
    

    rule {
      name = "ubuntu-libraries"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns = ["api.snapcraft.io","motd.ubuntu.com",]
    }

    rule {
      name = "microsoft-crls"
      protocols {
        type = "Http"
        port = 80
      }
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns = ["crl.microsoft.com",
                          "mscrl.microsoft.com",  
                          "crl3.digicert.com",
                          "ocsp.digicert.com"]
    }

    rule {
      name = "github-rules"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns = ["github.com"]
    }

    rule {
      name = "microsoft-metrics-rules"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns = ["*.prod.microsoftmetrics.com"]
    }

    rule {
      name = "aks-acs-rules"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns = ["acs-mirror.azureedge.net",
                           "*.docker.io",
                           "production.cloudflare.docker.com",
                          "*.azurecr.io"]
    }

    rule {
      name = "microsoft-login-rules"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns = ["login.microsoftonline.com"]
    }
  }

  network_rule_collection {
    name     = "aks-network-rule-collection"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "aks-global-network-rule"
      protocols             = ["TCP"]
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_addresses = ["AzureCloud"]
      destination_ports     = ["443", "9000"]
    }

    rule {
      name                  = "aks-ntp-network-rule"
      protocols             = ["UDP"]
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_addresses = ["*"]
      destination_ports     = ["123"]
    }
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "mlw_rule_collection" {
  name               = "mlw-afwpolicy-rcg"
  firewall_policy_id = azurerm_firewall_policy.base_policy.id
  priority           = 300
  application_rule_collection {
    name     = "mlw-app-rule-collection"
    priority = 200
    action   = "Allow"

    rule {
      name = "graph.windows.net"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns = ["graph.windows.net"]
    }

    rule {
      name = "anaconda.com"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns = ["anaconda.com", "*.anaconda.com"]
    }

    rule {
      name = "anaconda.org"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns = ["*.anaconda.org"]
    }
    
    rule {
      name = "pypi.org"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns = ["pypi.org"]
    }

    rule {
      name = "cloud.r-project.org"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns = ["cloud.r-project.org"]
    }

    rule {
      name = "pytorch.org"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns = ["*pytorch.org"]
    }

    rule {
      name = "tensorflow.org"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns = ["*.tensorflow.org"]
    }

    rule {
      name = "update.code.visualstudio.com"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns = ["update.code.visualstudio.com", "*.vo.msecnd.net"]
    }

    rule {
      name = "dc.applicationinsights.azure.com"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns = ["dc.applicationinsights.azure.com"]
    }

    rule {
      name = "dc.applicationinsights.microsoft.com"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns = ["dc.applicationinsights.microsoft.com"]
    }

    rule {
      name = "dc.services.visualstudio.com"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns = ["dc.services.visualstudio.com"]
    }      
  }

  network_rule_collection {
    name     = "mlw-network-rule-collection"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "Azure-Active-Directory"
      protocols             = ["TCP"]
      source_ip_groups      = [var.region1_mlw_spk_ip_g_id]      
      destination_addresses = ["AzureActiveDirectory"]
      destination_ports     = ["*"]
    }

    rule {
      name                  = "Azure-Machine-Learning"
      protocols             = ["TCP"]
      source_ip_groups      = [var.region1_mlw_spk_ip_g_id]      
      destination_addresses     = ["AzureMachineLearning"]
      destination_ports     = ["443"]
    }

    rule {
      name                  = "Azure-Resource-Manager"
      protocols             = ["TCP"]
      source_ip_groups      = [var.region1_mlw_spk_ip_g_id]      
      destination_addresses = ["AzureResourceManager"]
      destination_ports     = ["443"]
    }

    rule {
      name                  = "Azure-Storage"
      protocols             = ["TCP"]
      source_ip_groups      = [var.region1_mlw_spk_ip_g_id]      
      destination_addresses = ["Storage"]
      destination_ports     = ["443"]
    }

    rule {
      name                  = "Azure-Front-Door-Frontend"
      protocols             = ["TCP"]
      source_ip_groups      = [var.region1_mlw_spk_ip_g_id]      
      destination_addresses = ["AzureFrontDoor.Frontend"]
      destination_ports     = ["443"]
    }

    rule {
      name                  = "Azure-Container-Registry"
      protocols             = ["TCP"]
      source_ip_groups      = [var.region1_mlw_spk_ip_g_id]      
      destination_addresses = ["AzureContainerRegistry"]
      destination_ports     = ["443"]
    }

    rule {
      name                  = "Azure-Key-Vault"
      protocols             = ["TCP"]
      source_ip_groups      = [var.region1_mlw_spk_ip_g_id]      
      destination_addresses = ["AzureKeyVault"]
      destination_ports     = ["443"]
    }

    rule {
      name                  = "Microsoft-Container-Registry"
      protocols             = ["TCP"]
      source_ip_groups      = [var.region1_mlw_spk_ip_g_id]      
      destination_addresses = ["MicrosoftContainerRegistry"]
      destination_ports     = ["443"]
    }
  }    
}

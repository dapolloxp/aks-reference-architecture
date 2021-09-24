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
  priority           = 100

  network_rule_collection {
    name     = "hub_to_spoke_network_rule_collection"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "hub_to_spoke_global_network_rule"
      protocols             = ["TCP"]
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
    name     = "aks_app_rule_collection"
    priority = 200
    action   = "Allow"

    rule {
      name = "aks_service_tag"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdn_tags = ["AzureKubernetesService"]
    }
    

    rule {
      name = "ubuntu_libraries"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns = ["api.snapcraft.io","motd.ubuntu.com",]
    }

    rule {
      name = "microsoft_crls"
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
      name = "github_rules"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns = ["github.com"]
    }

    rule {
      name = "microsoft_metrics_rules"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns = ["*.prod.microsoftmetrics.com"]
    }

    rule {
      name = "aks_acs_rules"
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
      name = "microsoft_login_rules"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
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
      source_ip_groups = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns = ["AzureCloud"]
      destination_ports     = ["443", "9000"]
    }

    rule {
      name                  = "aks_ntp_network_rule"
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
    name     = "mlw_app_rule_collection"
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
    name     = "mlw_network_rule_collection"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "Azure_Active_Directory"
      protocols             = ["TCP"]
      source_ip_groups      = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns     = ["AzureActiveDirectory"]
      destination_ports     = ["*"]
    }

    rule {
      name                  = "Azure_Machine_Learning"
      protocols             = ["TCP"]
      source_ip_groups      = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns     = ["AzureMachineLearning"]
      destination_ports     = ["443"]
    }

    rule {
      name                  = "Azure_Resource_Manager"
      protocols             = ["TCP"]
      source_ip_groups      = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns     = ["AzureResourceManager"]
      destination_ports     = ["443"]
    }

    rule {
      name                  = "Azure_Storage"
      protocols             = ["TCP"]
      source_ip_groups      = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns     = ["Storage.${var.location}"]
      destination_ports     = ["443"]
    }

    rule {
      name                  = "Azure_Front_Door_Frontend"
      protocols             = ["TCP"]
      source_ip_groups      = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns     = ["AzureFrontDoor.Frontend"]
      destination_ports     = ["443"]
    }

    rule {
      name                  = "Azure_Container_Registry"
      protocols             = ["TCP"]
      source_ip_groups      = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns     = ["AzureContainerRegistry.${var.location}"]
      destination_ports     = ["443"]
    }

    rule {
      name                  = "Azure_Key_Vault"
      protocols             = ["TCP"]
      source_ip_groups      = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns     = ["AzureKeyVault.${var.location}"]
      destination_ports     = ["443"]
    }

    rule {
      name                  = "Microsoft_Container_Registry"
      protocols             = ["TCP"]
      source_ip_groups      = [var.region1_mlw_spk_ip_g_id]      
      destination_fqdns     = ["MicrosoftContainerRegistry.${var.location}"]
      destination_ports     = ["443"]
    }
  }    
}

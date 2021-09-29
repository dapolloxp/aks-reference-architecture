terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.78"
    }
  }
}
provider "azurerm" {
    features {} 
}

resource "random_string" "random" {
  length = 8
  upper = false
  special = false

}

#Monitoring Resource group 
resource "azurerm_resource_group" "mon_rg" {
    name                        = "rg-mon-core-prod-${var.location}"
    location                    = var.location
  tags = {
    "Workload" = "Core Infra"
    "Data Class" = "General"
    "Business Crit" = "Low"
  }
}

#Shared Services Resource Group
resource "azurerm_resource_group" "svc_rg" {
    name                        = "${var.svc_resource_group_name}-${var.location}"
    location                    = var.location
  tags = {}
  
  }
#Log Analytics WorkSpace
module "log_analytics" {
  source                          = "../../modules/log_analytics"
  resource_group_name             = azurerm_resource_group.mon_rg.name
  location                        = var.location
  law_name                        = "${var.law_prefix}-core-${azurerm_resource_group.mon_rg.location}-${random_string.random.result}"
}

#Hub Resource Group
resource "azurerm_resource_group" "hub_rg" {
  name     = "rg-net-core-hub-${var.location}"
  location = var.location
  tags     = var.tags
}

#Hub Vnet
module "hub_vnet" {
  
  source = "../../modules/networking/vnet"
  resource_group_name = azurerm_resource_group.hub_rg.name
  location            = azurerm_resource_group.hub_rg.location

  vnet_name             = "vnet-hub-${var.location}"
  address_space         = "10.1.0.0/16"
  dns_servers = ["168.63.129.16"]
}

#Hub subnets
module "hub_vnet_default_subnet"{
  
  source = "../../modules/networking/subnet"
  resource_group_name = azurerm_resource_group.hub_rg.name
  vnet_name = module.hub_vnet.vnet_name
  subnet_name = "snet-default"
  subnet_prefixes = ["10.1.1.0/24"]
  azure_fw_ip = module.azure_firewall.ip
}

#Hub IP Group
resource "azurerm_ip_group" "ip_group_hub" {
  name                = "hub-ipgroup"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  cidrs = ["10.1.0.0/16"]

}
#IP Group for MLW Spoke Vnet
resource "azurerm_ip_group" "ip_group_mlw_spoke" {
  name                = "mlw-spoke-ipgroup"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  cidrs = ["10.3.0.0/16"]
}

#Spoke Vnet Resource Group
resource "azurerm_resource_group" "spoke_vnet_rg" {
  name     = "rg-net-spoke-${var.location}"
  location = var.location
  tags     = var.tags
}

# Create spoke Vnet for MLW
module "spoke_vnet" {
  source = "../../modules/networking/vnet"
  resource_group_name = azurerm_resource_group.spoke_vnet_rg.name
  location            = azurerm_resource_group.spoke_vnet_rg.location
  vnet_name             = "vnet-spk-${var.location}"
  address_space         = "10.3.0.0/16"
  dns_servers = [module.azure_firewall.ip]
}

# Spoke Subnet
module "spoke_vnet_aks_subnet"{
  source = "../../modules/networking/subnet"
  resource_group_name = azurerm_resource_group.spoke_vnet_rg.name
  vnet_name = module.spoke_vnet.vnet_name
  subnet_name = "snet-aks"
  subnet_prefixes = ["10.3.2.0/24"]
  azure_fw_ip = module.azure_firewall.ip
}

# Spoke Subnet
module "spoke_vnet_training_subnet"{
  source = "../../modules/networking/subnet"
  resource_group_name = azurerm_resource_group.spoke_vnet_rg.name
  vnet_name = module.spoke_vnet.vnet_name
  subnet_name = "snet-training"
  subnet_prefixes = ["10.3.3.0/24"]
  azure_fw_ip = module.azure_firewall.ip
}

# Spoke Subnet
module "spoke_vnet_scoring_subnet"{
  source = "../../modules/networking/subnet"
  resource_group_name = azurerm_resource_group.spoke_vnet_rg.name
  vnet_name = module.spoke_vnet.vnet_name
  subnet_name = "snet-scoring"
  subnet_prefixes = ["10.3.4.0/24"]
  azure_fw_ip = module.azure_firewall.ip
}


# Peering between hub vnet and spoke vnet
module "peering_hub_to_spoke" {
  source = "../../modules/networking/peering_direction1"
  resource_group_nameA = azurerm_resource_group.hub_rg.name
  resource_group_nameB = azurerm_resource_group.spoke_vnet_rg.name
  netA_name            = module.hub_vnet.vnet_name
  netA_id              = module.hub_vnet.vnet_id
  netB_name            = module.spoke_vnet.vnet_name
  netB_id              = module.spoke_vnet.vnet_id
}

# Peering between hub1 and spk1
module "peering_spoke_to_hub" {
  source = "../../modules/networking/peering_direction2"
  resource_group_nameA = azurerm_resource_group.hub_rg.name
  resource_group_nameB = azurerm_resource_group.spoke_vnet_rg.name
  netA_name            = module.hub_vnet.vnet_name
  netA_id              = module.hub_vnet.vnet_id
  netB_name            = module.spoke_vnet.vnet_name
  netB_id              = module.spoke_vnet.vnet_id
}


module "private_dns" {
  source = "../../modules/azure_dns"
  resource_group_name             = azurerm_resource_group.svc_rg.name
  location                        = var.location
  hub_virtual_network_id          = module.hub_vnet.vnet_id
}

# Bastion Host

module "bastion" { 
  source = "../../modules/azure_bastion"
  resource_group_name       = azurerm_resource_group.hub_rg.name
  location                  = azurerm_resource_group.hub_rg.location
  azurebastion_name         = var.azurebastion_name
  azurebastion_vnet_name    = module.hub_vnet.vnet_name
  azurebastion_addr_prefix  = "10.1.250.0/24"
}

#Hub Azure Firewall
module "azure_firewall" { 
    source                      = "../../modules/azure_firewall"
    resource_group_name         = azurerm_resource_group.hub_rg.name
    location                    = azurerm_resource_group.hub_rg.location
    azurefw_name                = "${var.azurefw_name}-${random_string.random.result}"
    azurefw_vnet_name           = module.hub_vnet.vnet_name
    azurefw_addr_prefix         = var.azurefw_addr_prefix
    law_id                      = module.log_analytics.log_analytics_id
    azfw_diag_name              = "monitoring-${random_string.random.result}"
    region1_mlw_spk_ip_g_id     = azurerm_ip_group.ip_group_mlw_spoke.id
    region1_hub_ip_g_id         = azurerm_ip_group.ip_group_hub.id
}

# Jump host 

module "jump_host" { 
    source                               = "../../modules/jump_host"
    resource_group_name                  = azurerm_resource_group.hub_rg.name
    location                             = azurerm_resource_group.hub_rg.location
    jump_host_name                       = var.jump_host_name
    jump_host_vnet_name                  = module.hub_vnet.vnet_name
    jump_host_addr_prefix                = var.jump_host_addr_prefix
    jump_host_private_ip_addr            = var.jump_host_private_ip_addr
    jump_host_vm_size                    = var.jump_host_vm_size
    jump_host_admin_username             = var.jump_host_admin_username
    jump_host_password                   = var.jump_host_password
    key_vault_id                         = module.keyvault.kv_key_zone_id
    kv_rg                                = azurerm_resource_group.spoke_shared_rg.name
    azure_fw_ip                          = module.azure_firewall.ip
    depends_on = [
      azurerm_resource_group.spoke_shared_rg
    ]
}

#Spoke shared resource group
resource "azurerm_resource_group" "spoke_shared_rg" {
  #provider = azurerm.identity
  name     = "rg-shared-mlw-spoke-${var.location}"
  location = var.location
  tags     = var.tags
}

#Spoke ACR
module "acr" {
  source = "../../modules/acr"
  resource_group_name             = azurerm_resource_group.spoke_shared_rg.name
  location                        = var.location
  subnet_id                       = module.spoke_vnet_training_subnet.subnet_id
  acr_name                        = "${var.acr_name}${random_string.random.result}"
  acr_private_zone_id             = module.private_dns.acr_private_zone_id

}
#Spoke Storage Account
module "storage_account" {
  source = "../../modules/storage_account"
  resource_group_name                   = azurerm_resource_group.spoke_shared_rg.name
  location                              = var.location
  subnet_id                             = module.spoke_vnet_training_subnet.subnet_id
  storage_account_name                  = "${var.storage_account_name}${random_string.random.result}"
  storage_account_blob_private_zone_id  = module.private_dns.storage_account_blob_private_zone_id
  storage_account_file_private_zone_id  = module.private_dns.storage_account_file_private_zone_id
}

#Spoke Key Vault
module "keyvault" {
    
    source  = "../../modules/key_vault"
    resource_group_name   = azurerm_resource_group.spoke_shared_rg.name
    location              = azurerm_resource_group.spoke_shared_rg.location
    keyvault_name         = "akv-${random_string.random.result}"
    subnet_id             = module.spoke_vnet_training_subnet.subnet_id
    kv_private_zone_id    = module.private_dns.kv_private_zone_id
    kv_private_zone_name  = module.private_dns.kv_private_zone_name
}


#Spoke App Insights
module "app_insights"{
  source = "../../modules/app_insights"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke_shared_rg.name
  app_insights_name   = "${var.app_insights_name}-${random_string.random.result}"
}

#Spoke Machine Learning Workspace
module "machine_learning_workspace" {
  source = "../../modules/machine_learning_workspace"
  mlw_name                = "${var.mlw_name}-${random_string.random.result}"
  location                = var.location
  resource_group_name     = azurerm_resource_group.spoke_shared_rg.name
  application_insights_id = module.app_insights.app_insights_id
  key_vault_id            = module.keyvault.kv_id
  storage_account_id      = module.storage_account.storage_account_id
  container_registry_id   = module.acr.acr_id
  subnet_id               = module.spoke_vnet_training_subnet.subnet_id
  machine_learning_workspace_notebooks_zone_id  = module.private_dns.machine_learning_workspace_notebooks_zone_id
  machine_learning_workspace_api_zone_id        = module.private_dns.machine_learning_workspace_api_zone_id
}
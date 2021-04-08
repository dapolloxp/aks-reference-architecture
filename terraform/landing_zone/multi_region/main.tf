terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.52"
    }
  }
}
provider "azurerm" {
    features {} 
}
/*
provider "azurerm" {
    features {} 
    alias = "management"
    subscription_id = var.management_subscription_id
}

provider "azurerm" {
    features {} 
    alias = "identity"
    subscription_id = var.identity_subscription_id
}

provider "azurerm" {
    features {} 
    alias = "connectivity"
    subscription_id = var.connectivity_subscription_id
}*/

# Resource group 
resource "azurerm_resource_group" "mon_rg" {
    #provider = azurerm.management
    name                        = var.mon_resource_group_name
    location                    = var.location
  tags = {
    "Workload" = "Core Infra"
    "Data Class" = "General"
    "Business Crit" = "Low"
  }
}
resource "azurerm_resource_group" "svc_rg" {
    #provider = azurerm.management
    name                        = var.svc_resource_group_name
    location                    = var.location
  tags = {
    "Workload" = "Core Infra"
    "Data Class" = "General"
    "Business Crit" = "High"
  }
}
/*
module "log_analytics" {
  #providers = {azurerm = azurerm.management}
  source                          = "../../modules/log_analytics"
  resource_group_name             = azurerm_resource_group.mon_rg.name
  location                        = var.location
  law_name               = "${var.law_prefix}-core-${var.corp_prefix}-001"
}

module "security_center_workspace_management"{
  #providers = {azurerm = azurerm.management}
  source = "../../modules/security_center_workspace"
  subscription_id = var.management_subscription_id
  law_id = module.log_analytics.log_analytics_id

  depends_on = [module.log_analytics]
}

module "security_center_workspace_connectivity"{
  #providers = {azurerm = azurerm.connectivity}
  source = "../../modules/security_center_workspace"
  subscription_id = var.connectivity_subscription_id
  law_id = module.log_analytics.log_analytics_id

  depends_on = [module.log_analytics]
}

module "security_center_workspace_identity"{
  #providers = {azurerm = azurerm.identity}
  source =  "../../modules/security_center_workspace"
  subscription_id = var.identity_subscription_id
  law_id = module.log_analytics.log_analytics_id

  depends_on = [module.log_analytics]
}

module "automation_account" {
  #providers = {azurerm = azurerm.management}
  source                          = "../../modules/automation_account"
  resource_group_name             = azurerm_resource_group.mon_rg.name
  location                        = var.location
  name                            = "auto-core-${var.location}-${var.corp_prefix}"
  law_id                          = module.log_analytics.log_analytics_id
  law_name                        = module.log_analytics.log_analytics_name

  depends_on = [module.log_analytics]
}
*/

resource "azurerm_resource_group" "hub_region1" {
  #provider = azurerm.connectivity
  name     = "net-core-hub-${var.region1_loc}-rg"
  location = var.region1_loc
  tags     = var.tags
}

resource "azurerm_resource_group" "hub_region2" {
  #provider = azurerm.connectivity
  name     = "net-core-hub-${var.region2_loc}-rg"
  location = var.region2_loc
  tags     = var.tags
}

module "hub_region1" {
  
  source = "../../modules/networking/vnet"
  resource_group_name = azurerm_resource_group.hub_region1.name
  location            = azurerm_resource_group.hub_region1.location

  vnet_name             = "vnet-hub-${var.region1_loc}"
  address_space         = "10.1.0.0/16"
  default_subnet_prefixes = ["10.1.1.0/24"]
  dns_servers = ["168.63.129.16"]
}

module "hub_region2" {
  
  source = "../../modules/networking/vnet"
  resource_group_name = azurerm_resource_group.hub_region2.name
  location            = azurerm_resource_group.hub_region2.location
  vnet_name             = "vnet-hub-${var.region2_loc}"
  address_space         = "10.2.0.0/16"
  default_subnet_prefixes = ["10.2.1.0/24"]
  dns_servers = ["168.63.129.16"]
}
# Peering between hub1 and hub2
module "peering_hubs" {
  #providers = {azurerm = azurerm.connectivity}
  source = "../../modules/networking/peering_both"
  resource_group_nameA = azurerm_resource_group.hub_region1.name
  resource_group_nameB = azurerm_resource_group.hub_region2.name
  netA_name            = module.hub_region1.vnet_name
  netA_id              = module.hub_region1.vnet_id
  netB_name            = module.hub_region2.vnet_name
  netB_id              = module.hub_region2.vnet_id
}

resource "azurerm_resource_group" "id_spk_region1" {
  #provider = azurerm.identity
  name     = "net-aks-spk-${var.region1_loc}-rg"
  location = var.region1_loc
  tags     = var.tags
}

# Create idenity spoke for region1
module "id_spk_region1" {
  #providers = {azurerm = azurerm.identity}
  source = "../../modules/networking/vnet"
  resource_group_name = azurerm_resource_group.id_spk_region1.name
  location            = azurerm_resource_group.id_spk_region1.location
  vnet_name             = "vnet-aks-spk-${var.region1_loc}"
  address_space         = "10.3.0.0/16"
  default_subnet_prefixes = ["10.3.1.0/24"]
  dns_servers = ["168.63.129.16"]
}

# Peering between hub1 and spk1
module "peering_aks_spk_Region1_1" {
  #providers = {azurerm = azurerm.connectivity}
  source = "../../modules/networking/peering_direction1"
  resource_group_nameA = azurerm_resource_group.hub_region1.name
  resource_group_nameB = azurerm_resource_group.id_spk_region1.name
  netA_name            = module.hub_region1.vnet_name
  netA_id              = module.hub_region1.vnet_id
  netB_name            = module.id_spk_region1.vnet_name
  netB_id              = module.id_spk_region1.vnet_id
}

# Peering between hub1 and spk1
module "peering_id_spk_Region1_2" {
  #providers = {azurerm = azurerm.identity}
  source = "../../modules/networking/peering_direction2"
  resource_group_nameA = azurerm_resource_group.hub_region1.name
  resource_group_nameB = azurerm_resource_group.id_spk_region1.name
  netA_name            = module.hub_region1.vnet_name
  netA_id              = module.hub_region1.vnet_id
  netB_name            = module.id_spk_region1.vnet_name
  netB_id              = module.id_spk_region1.vnet_id

  #depends_on = [module.peering_id_spk_Region1_1]
}

resource "azurerm_resource_group" "id_spk_region2" {
  #provider = azurerm.identity
  name     = "net-aks-spk-${var.region2_loc}-rg"
  location = var.region2_loc
  tags     = var.tags
}

# Create idenity spoke for region2
module "id_spk_region2" {
  #providers = {azurerm = azurerm.identity}
  source = "../../modules/networking/vnet"
  resource_group_name = azurerm_resource_group.id_spk_region2.name
  location            = azurerm_resource_group.id_spk_region2.location
  vnet_name             = "vnet-aks-spk-${var.region2_loc}"
  address_space         = "10.4.0.0/16"
  default_subnet_prefixes = ["10.4.1.0/24"]
  dns_servers = ["168.63.129.16"]
}

##Add Additional subnets Needed
#module "id_spk_region2_shared_subnet"{
#
#}

# Peering between hub2 and id_spk2
module "peering_id_spk_Region2_1" {
  #providers = {azurerm = azurerm.connectivity}
  source = "../../modules/networking/peering_direction1"
  resource_group_nameA = azurerm_resource_group.hub_region2.name
  resource_group_nameB = azurerm_resource_group.id_spk_region2.name
  netA_name            = module.hub_region2.vnet_name
  netA_id              = module.hub_region2.vnet_id
  netB_name            = module.id_spk_region2.vnet_name
  netB_id              = module.id_spk_region2.vnet_id
}

# Peering between hub2 and id_spk2
module "peering_id_spk_Region2_2" {
  #providers = {azurerm = azurerm.identity}
  source = "../../modules/networking/peering_direction2"

  resource_group_nameA = azurerm_resource_group.hub_region2.name
  resource_group_nameB = azurerm_resource_group.id_spk_region2.name
  netA_name            = module.hub_region2.vnet_name
  netA_id              = module.hub_region2.vnet_id
  netB_name            = module.id_spk_region2.vnet_name
  netB_id              = module.id_spk_region2.vnet_id

  depends_on = [module.peering_id_spk_Region2_1]
}

#resource "azurerm_network_ddos_protection_plan" "hub1" {
#  name                = "${var.corp_prefix}-protection-plan"
#  location            = azurerm_resource_group.hub_region1.location
#  resource_group_name = azurerm_resource_group.hub_region1.name
#}

# Bastion Host
/*
module "bastion_region1" {
  providers = {azurerm = azurerm.connectivity}
  source = "../../modules/azure_bastion"
  resource_group_name  = azurerm_resource_group.hub_region1.name
  location             = var.region1_loc
  azurebastion_name = var.azurebastion_name
  azurebastion_vnet_name = module.hub_region1.vnet_name
  azurebastion_addr_prefix = "10.1.250.0/24"
}*/

# Azure Firewall 
/*
module "azure_firewall" { 
    providers = {azurerm = azurerm.connectivity}
    source                      = "../../modules/azure_firewall"
    resource_group_name         = azurerm_resource_group.hub_region1.name
    location                    = azurerm_resource_group.hub_region1.location
    azurefw_name                = var.azurefw_name
    azurefw_vnet_name           = module.hub_region1.vnet_name
    azurefw_addr_prefix         = var.azurefw_addr_prefix
    law_id                      = module.log_analytics.log_analytics_id
}*/

# Jump host  Errors on creation with VMExtention is commented out
/*
module "jump_host" { 
    providers = {azurerm = azurerm.connectivity}
    source                              = "../../modules/jump_host"
    resource_group_name                 = azurerm_resource_group.hub_region1.name
    location                            = azurerm_resource_group.hub_region1.location
    jump_host_name                       = var.jump_host_name
    jump_host_vnet_name                  = module.hub_region1.vnet_name
    jump_host_addr_prefix                = var.jump_host_addr_prefix
    jump_host_private_ip_addr            = var.jump_host_private_ip_addr
    jump_host_vm_size                    = var.jump_host_vm_size
    jump_host_admin_username             = var.jump_host_admin_username
    jump_host_password                   = var.jump_host_password
}*/

resource "azurerm_resource_group" "id_shared_region1" {
  #provider = azurerm.identity
  name     = "shared-svc-spk-${var.region1_loc}-rg"
  location = var.region1_loc
  tags     = var.tags
}
resource "azurerm_resource_group" "id_shared_region2" {
  #provider = azurerm.identity
  name     = "shared-svc-spk-${var.region2_loc}-rg"
  location = var.region2_loc
  tags     = var.tags
}

#Add Additional subnets Needed
module "id_spk_region1_shared_subnet"{
  #providers = {azurerm = azurerm.identity}
  source = "../../modules/networking/subnet"
  resource_group_name = azurerm_resource_group.id_spk_region1.name
  vnet_name = module.id_spk_region1.vnet_name
  subnet_name = "shared"
  subnet_prefixes = ["10.3.2.0/24"]
}

#Need to fix Private Endpoint and location of DNS Zone
/*
module "keyvault" {
    providers = {azurerm = azurerm.identity}
    source  = "../../modules/key_vault"
    resource_group_name = azurerm_resource_group.id_shared_region1.name
    location = azurerm_resource_group.id_shared_region1.location
    keyvault_name  = "kv-${var.corp_prefix}-${var.region1_loc}"
    shared_subnetid  = module.id_spk_region1_shared_subnet.shared_subnet_id
    hub_virtual_network_id = module.hub_region1.vnet_id
    spoke_virtual_network_id = module.id_spk_region1.vnet_id

    depends_on = [module.id_spk_region1_shared_subnet]
}*/
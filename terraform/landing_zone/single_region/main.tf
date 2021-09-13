terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.63"
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

# Resource group 
resource "azurerm_resource_group" "mon_rg" {
    #provider = azurerm.management
    #name                        = var.mon_resource_group_name
    name                        = "mon-core-prod-${var.location}-rg"
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

module "log_analytics" {
  #providers = {azurerm = azurerm.management}
  source                          = "../../modules/log_analytics"
  resource_group_name             = azurerm_resource_group.mon_rg.name
  location                        = var.location
  law_name                        = "${var.law_prefix}-core-${azurerm_resource_group.mon_rg.location}-${random_string.random.result}"
}

resource "azurerm_resource_group" "hub_region1" {
  #provider = azurerm.connectivity
  name     = "net-core-hub-${var.region1_loc}-rg"
  location = var.region1_loc
  tags     = var.tags
}



module "hub_region1" {
  
  source = "../../modules/networking/vnet"
  resource_group_name = azurerm_resource_group.hub_region1.name
  location            = azurerm_resource_group.hub_region1.location

  vnet_name             = "vnet-hub-${var.region1_loc}"
  address_space         = "10.1.0.0/16"
 # default_subnet_prefixes = ["10.1.1.0/24"]
  dns_servers = ["168.63.129.16"]
}

module "hub_region1_default_subnet"{
  
  source = "../../modules/networking/subnet"
  resource_group_name = azurerm_resource_group.hub_region1.name
  vnet_name = module.hub_region1.vnet_name
  subnet_name = "default-subnet"
  subnet_prefixes = ["10.1.1.0/24"]
  azure_fw_ip = module.azure_firewall_region1.ip
}

resource "azurerm_ip_group" "ip_g_region1_hub" {
  name                = "region1-hub-ipgroup"
  location            = azurerm_resource_group.hub_region1.location
  resource_group_name = azurerm_resource_group.hub_region1.name
  cidrs = ["10.1.0.0/16"]

}

resource "azurerm_ip_group" "ip_g_region1_aks_spoke" {
  name                = "region1-aks-spoke-ipgroup"
  location            = azurerm_resource_group.hub_region1.location
  resource_group_name = azurerm_resource_group.hub_region1.name
  cidrs = ["10.3.0.0/16"]
}

resource "azurerm_ip_group" "ip_g_region1_pe_spoke" {
  name                = "region1-pe-spoke-ipgroup"
  location            = azurerm_resource_group.hub_region1.location
  resource_group_name = azurerm_resource_group.hub_region1.name
  cidrs = ["10.4.0.0/16"]
}


resource "azurerm_resource_group" "id_spk_region1" {
  #provider = azurerm.identity
  name     = "net-spk-${var.region1_loc}-rg"
  location = var.region1_loc
  tags     = var.tags
}

# Create spoke for region1
module "id_spk_region1" {
  #providers = {azurerm = azurerm.identity}
  source = "../../modules/networking/vnet"
  resource_group_name = azurerm_resource_group.id_spk_region1.name
  location            = azurerm_resource_group.id_spk_region1.location
  vnet_name             = "vnet-spk-${var.region1_loc}"
  address_space         = "10.3.0.0/16"
  # default_subnet_prefixes = ["10.3.1.0/24"]
  dns_servers = [module.azure_firewall_region1.ip]
}

#################################

module "id_spk_region1_default_subnet" {
  
  source = "../../modules/networking/subnet"
  resource_group_name = azurerm_resource_group.id_spk_region1.name
  vnet_name = module.id_spk_region1.vnet_name
  subnet_name = "default-subnet"
  //subnet_prefixes = ["10.3.1.0/24"]
  subnet_prefixes = ["10.3.4.0/22"]
  azure_fw_ip = module.azure_firewall_region1.ip
}



# Peering between hub1 and spk1
module "peering_spk_Region1_1" {
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
}


module "acr" {
  source = "../../modules/acr"
  resource_group_name             = azurerm_resource_group.id_shared_region1.name
  location                        = var.location
  subnet_id                       = module.id_spk_region1_default_subnet.subnet_id
  //subnet_id                       = module.id_pe_region1_default_subnet.subnet_id
  acr_name                        = "${var.acr_name}${random_string.random.result}"
  acr_private_zone_id             = module.private_dns.acr_private_zone_id

}

module "private_dns" {
  source = "../../modules/azure_dns"
  resource_group_name             = azurerm_resource_group.svc_rg.name
  location                        = var.location
  hub_virtual_network_id          = module.hub_region1.vnet_id
}


# Bastion Host

module "bastion_region1" {
  #providers = {azurerm = azurerm.connectivity}
  source = "../../modules/azure_bastion"
  resource_group_name       = azurerm_resource_group.hub_region1.name
  location                  = azurerm_resource_group.hub_region1.location
  azurebastion_name         = var.azurebastion_name_01
  azurebastion_vnet_name    = module.hub_region1.vnet_name
  azurebastion_addr_prefix  = "10.1.250.0/24"
}


module "azure_firewall_region1" { 
    source                      = "../../modules/azure_firewall"
    resource_group_name         = azurerm_resource_group.hub_region1.name
    location                    = azurerm_resource_group.hub_region1.location
    azurefw_name                = "${var.azurefw_name_r1}-${random_string.random.result}"
    azurefw_vnet_name           = module.hub_region1.vnet_name
    azurefw_addr_prefix         = var.azurefw_addr_prefix_r1
    sc_law_id                   = module.log_analytics.log_analytics_id
    region1_aks_spk_ip_g_id     = azurerm_ip_group.ip_g_region1_aks_spoke.id
}

# Jump host  Errors on creation with VMExtention is commented out

module "jump_host" { 
    #providers = {azurerm = azurerm.connectivity}
    source                               = "../../modules/jump_host"
    resource_group_name                  = azurerm_resource_group.hub_region1.name
    location                             = azurerm_resource_group.hub_region1.location
    jump_host_name                       = var.jump_host_name
    jump_host_vnet_name                  = module.hub_region1.vnet_name
    jump_host_addr_prefix                = var.jump_host_addr_prefix
    jump_host_private_ip_addr            = var.jump_host_private_ip_addr
    jump_host_vm_size                    = var.jump_host_vm_size
    jump_host_admin_username             = var.jump_host_admin_username
    jump_host_password                   = var.jump_host_password
    key_vault_id                         = module.hub_keyvault.kv_key_zone_id
    kv_rg                                = azurerm_resource_group.id_shared_region1.name
    depends_on = [
      azurerm_resource_group.id_shared_region1
    ]
}

resource "azurerm_resource_group" "id_shared_region1" {
  #provider = azurerm.identity
  name     = "shared-svc-spk-${var.region1_loc}-rg"
  location = var.region1_loc
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
  azure_fw_ip = module.azure_firewall_region1.ip
}


#Need to fix Private Endpoint and location of DNS Zone

module "hub_keyvault" {
    
    source  = "../../modules/key_vault"
    resource_group_name   = azurerm_resource_group.id_shared_region1.name
    location              = azurerm_resource_group.id_shared_region1.location
    keyvault_name         = "kv-${random_string.random.result}"
    shared_subnetid       = module.id_spk_region1_shared_subnet.subnet_id
    kv_private_zone_id    = module.private_dns.kv_private_zone_id
    kv_private_zone_name  = module.private_dns.kv_private_zone_name
    depends_on            = [module.id_spk_region1_shared_subnet]
}
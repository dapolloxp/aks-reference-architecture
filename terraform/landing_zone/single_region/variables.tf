variable "mon_resource_group_name" {
  type        = string
  description = "Azure monitoring Resource Group"
  default     = "mon-core-prod-rg"
}

variable "svc_resource_group_name" {
  type        = string
  description = "Shared Services Resource Group"
  default     = "svc-core-prod-rg"
}

variable "servicebus-name" {
  type    = string
  default = "dapolinasb10"
}

variable "location" {
  type    = string
  default = "eastus2"
}

variable "corp_prefix" {
  type        = string
  description = "Corp name Prefix"
  default     = "dapolina0"
}

# LAW module

variable "law_prefix" {
  type    = string
  default = "law"
}


variable "region1_loc" {
  default = "eastus2"
}

variable "region2_loc" {
  default = "centralus"
}

variable "tags" {
  description = "ARM resource tags to any resource types which accept tags"
  type        = map(string)

  default = {
    owner = "dapolina"
  }
}

/*
# Windows DC Variables
variable "compute_boot_volume_size_in_gb" {
  description = "Boot volume size of jumpbox instance"
  default     = 128
}

variable "enable_accelerated_networking" {
  default = "false"
}

variable "boot_diag_SA_endpoint" {
  default = "0"
}

variable "os_offer" {
  default = "WindowsServer"
}

variable "os_publisher" {
  default = "MicrosoftWindowsServer"
}

variable "os_sku" {
  default = "2019-Datacenter"
}

variable "os_version" {
  default = "latest"
}

variable "admin_username" {
  default = "sysadmin"
}

#variable "admin_password" {
#}

variable "storage_account_type" {
  default = "Standard_LRS"
}
*/

/*
# DSC Variables
variable dsc_config {
  default = "blank"
}

variable dsc_mode {
  default = "applyAndMonitor"
}
*/

# Azure Bastion module
variable "azurebastion_name_01" {
  type    = string
  default = "corp-bastion-svc_01"
}
variable "azurebastion_addr_prefix" {
  type        = string
  description = "Azure Bastion Address Prefix"
  default     = "10.1.250.0/24"
}

# Azure Firewall
variable "azurefw_name_r1" {
  type    = string
  default = "fwhub1"
}
variable "azurefw_name_r2" {
  type    = string
  default = "fwhub2"
}
variable "azurefw_addr_prefix_r1" {
  type        = string
  description = "Azure Firewall VNET prefix"
  default     = "10.1.254.0/24"
}
variable "azurefw_addr_prefix_r2" {
  type        = string
  description = "Azure Firewall VNET prefix"
  default     = "10.2.254.0/24"
}
# ACR


variable "acr_name" {
  type    = string
  default = "dapolinaacr01"
}

# Jump host1  module
variable "jump_host_name" {
  type    = string
  default = "jumphostvm"
}
variable "jump_host_addr_prefix" {
  type        = string
  description = "Azure Jump Host Address Prefix"
  default     = "10.1.251.0/24"
}
variable "jump_host_private_ip_addr" {
  type        = string
  description = "Azure Jump Host Address"
  default     = "10.1.251.5"
}
variable "jump_host_vm_size" {
  type        = string
  description = "Azure Jump Host VM SKU"
  default     = "Standard_DS3_v2"
}
variable "jump_host_admin_username" {
  type        = string
  description = "Azure Admin Username"
  default     = "azureadmin"
}
variable "jump_host_password" {
  sensitive = true
  type      = string
}




# jumphost2


variable "jump_host_addr_prefix2" {
  type        = string
  description = "Azure Jump Host Address Prefix"
  default     = "10.2.251.0/24"
}
variable "jump_host_private_ip_addr2" {
  type        = string
  description = "Azure Jump Host Address"
  default     = "10.2.251.5"
}
/*
variable "management_subscription_id" {
    type        = string 
    description = "Subscription Id for Managemnet subscription"
    default = "51444e62-8fad-49fc-affe-dade00c18dd2"
}

variable "connectivity_subscription_id" {
    type        = string 
    description = "Subscription Id for Connectivity subscription"
    default = "2ea80eb6-d4a4-44f8-9bbe-4b027ad71af3"
}

variable "identity_subscription_id" {
    type        = string 
    description = "Subscription Id for Identity subscription"
    default = "962d4162-7af9-411f-8b1f-3269675d8766"
}

*/
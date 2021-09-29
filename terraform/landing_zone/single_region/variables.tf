variable "mon_resource_group_name" {
    type        = string 
    description = "Azure monitoring Resource Group"
    default     = "rg-mon-core-prod"
}

variable "svc_resource_group_name" {
    type        = string 
    description = "Shared Services Resource Group"
    default     = "rg-pdz-core-prod"
}

variable "location" {
    type = string
} 

variable "corp_prefix" {
    type        = string 
    description = "Corp name Prefix"
    default     = "corp"
}

# LAW module

variable law_prefix {
    type       = string
    default    = "log"
}

variable "tags" {
  description = "ARM resource tags to any resource types which accept tags"
  type        = map(string)

  default = {
    environment  = "dev"
  }
}

# Azure Bastion module
variable "azurebastion_name" {
    type        = string
    default     = "bas-corp-svc"
}
variable "azurebastion_addr_prefix" {
    type        = string 
    description = "Azure Bastion Address Prefix"
    default     = "10.1.250.0/24"
}

# Azure Firewall
variable "azurefw_name" {
    type        = string
    default     = "afw"
}

variable "azurefw_addr_prefix" {
    type        = string 
    description = "Azure Firewall VNET prefix"
    default     = "10.1.254.0/24"
}


#Storage Account
variable "storage_account_name" {
  type = string
  default = "st"
}

# ACR
variable "acr_name" {
  type = string
  default = "acr"
}

# Jump host  module
variable "jump_host_name" {
    type        = string
    default     = "vmjumphost"
}
variable "jump_host_addr_prefix" {
    type        = string 
    description = "Azure Jump Host Address Prefix"
    default     = "10.1.2.0/24"  
}
variable "jump_host_private_ip_addr" {
    type        = string 
    description = "Azure Jump Host Address"
    default     = "10.1.2.5"
}
variable "jump_host_vm_size" {
    type        = string 
    description = "Azure Jump Host VM SKU"
    default     = "Standard_DS3_v2"
}
variable "jump_host_admin_username" {
    type        = string 
    description = "Azure Admin Username"
    default = "azureadmin"
}
variable "jump_host_password" {
    type        = string 
    sensitive   = true
}

#App Insights
variable "app_insights_name" {
  type = string
  default = "appi"
}

#Machine Learning Workspace
variable "mlw_name" {
  type = string
  default = "mlw"
}
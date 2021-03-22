variable "location" {}
variable "resource_group_name" {}
variable "aks_spoke_subnet_id" {}
variable "spoke_virtual_network_id" {}
variable "hub_virtual_network_id" {}
variable "machine_type" {
  description = "The Azure Machine Type for the AKS Node Pool"
  default = "Standard_D4_v2"
}
variable "service_cidr" {
  description = "Service CIDR"
  default = "10.211.0.0/16"
}
variable "dns_service_ip" {
  description = "dns_service_ip"
  default = "10.211.0.10"
}
variable "docker_bridge_cidr" {
  description = "Docker bridge CIDR"
  default = "172.17.0.1/16"
}

variable "default_node_pool_size" {
  description = "The default number of VMs for the AKS Node Pool"
  default = 1
}

variable "kubernetes_version" {
    description = "The Kubernetes version to use for the cluster."
    default =  "1.18.10"
}
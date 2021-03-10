#resource_group_name         = "sc-hub-rg"
#spoke_resource_group_name   = "sc-spoke-rg"
# spring_cloud_rg
location                    = "East US 2"
#sc_resource_group_name      = "sc-svc-rg"
#sc_prefix                   = "sc"
# Hub-Spoke Parameters
#hub_vnet_name               = "hub-vnet" 
#hub_vnet_addr_prefix        = "10.230.0.0/16"
#spoke_vnet_name             = "spoke-vnet" 
#spoke_vnet_addr_prefix      = "10.231.0.0/16"

# Azure Firewall Parameters
##azurefw_name                = "corp-azurefw"
#azurefw_addr_prefix         = "10.230.0.0/26"

# Azure Bastion Parameters 
#azurebastion_name           = "corp-bastion-svc"
#azurebastion_addr_prefix    = "10.230.1.0/27"

# MySQL Parameters

my_sql_admin                = "mysqladminun"
my_sql_password             = "H@Sh1CoR3!"

# Jump host module           
jump_host_name                       = "vmjumphost"
#jump_host_addr_prefix                = "10.230.4.0/28"
#jump_host_private_ip_addr            = "10.230.4.5"
#jump_host_ssh_source_addr_prefixes   = ["10.230.1.0/27"]
#jump_host_vm_size                    = "Standard_DS3_v2"
jump_host_admin_username             = "azureuser"
#jump_host_pub_key_name               = "/Users/davidapolinar/.ssh/id_rsa.pub"
jump_host_password                   = "1@g2Jbk7$P@ssw0rd"

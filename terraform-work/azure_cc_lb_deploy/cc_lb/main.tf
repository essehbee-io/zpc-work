# generate a random string
resource "random_string" "suffix" {
  length = 8
  upper = false
  special = false
}

############################################################################################################################
#### The following lines generates a new SSH key pair and stores the PEM file locally. The public key output is used    ####
#### as the ssh_key passed variable to the cc_vm module for admin_ssh_key public_key authentication                     ####
#### This is not recommended for production deployments. Please consider modifying to pass your own custom              ####
#### public key file located in a secure location                                                                       ####
############################################################################################################################
# Generate a new private key for ssh login to Cloud Connector
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits = 4096
}
output "tls_private_key" {
  value = tls_private_key.key.private_key_pem
  sensitive = true
}

# save the private key locally
resource "null_resource" "save-key" {
  triggers = {
    key = tls_private_key.key.private_key_pem
  }

# set key file to appropriate execution permissions
  provisioner "local-exec" {
    command = <<EOF
      echo "${tls_private_key.key.private_key_pem}" > ${var.name_prefix}-key-${random_string.suffix.result}.pem
      chmod 0600 ${var.name_prefix}-key-${random_string.suffix.result}.pem
EOF
  }
}

###########################################################################################################################
###########################################################################################################################

## Create the user_data file
locals {
  userdata = <<USERDATA
[ZSCALER]
CC_URL=${var.cc_vm_prov_url}
AZURE_VAULT_URL=${var.azure_vault_url}
HTTP_PROBE_PORT=${var.http_probe_port}
USERDATA
}

resource "local_file" "user-data-file" {
  content  = local.userdata
  filename = "user_data"
}


# 1. Network Infra
# Create Resource Group or reference existing
resource "azurerm_resource_group" "main" {
  count    = var.byo_rg == false ? 1 : 0
  name     = "${var.name_prefix}-rg-${random_string.suffix.result}"
  location = var.arm_location
}

data "azurerm_resource_group" "selected" {
  name     = var.byo_rg == false ? azurerm_resource_group.main.*.name[0] : var.byo_rg_name
}


# Create Virtual Network or reference existing
resource "azurerm_virtual_network" "vnet1" {
  count               = var.byo_vnet == false ? 1 : 0
  name                = "${var.name_prefix}-vnet1-${random_string.suffix.result}"
  address_space       = [
    var.network_address_space]
  location            = var.arm_location
  resource_group_name = data.azurerm_resource_group.selected.name
}

data "azurerm_virtual_network" "selected" {
  name                = var.byo_vnet == false ? azurerm_virtual_network.vnet1.*.name[0] : var.byo_vnet_name
  resource_group_name = var.byo_vnet == false ? azurerm_virtual_network.vnet1.*.resource_group_name[0] : var.byo_vnet_subnets_rg_name
}



# Create Public IP for NAT Gateway or reference existing
resource "azurerm_public_ip" "nat-pip" {
  count                   = var.byo_pip_address == false ? 1 : 0
  name                    = "${var.name_prefix}-public-ip1-${random_string.suffix.result}"
  location                = var.arm_location
  resource_group_name     = data.azurerm_resource_group.selected.name
  allocation_method       = "Static"
  sku                     = "Standard"
  idle_timeout_in_minutes = 30
}

data "azurerm_public_ip" "selected" {
  name                = var.byo_pip_address == false ? azurerm_public_ip.nat-pip.*.name[0]: var.byo_pip_name
  resource_group_name = var.byo_pip_address == false ? azurerm_public_ip.nat-pip.*.resource_group_name[0] : var.byo_pip_rg
}


# Create NAT Gateway or reference an existing
resource "azurerm_nat_gateway" "nat-gw1" {
  count                   = var.byo_nat_gw == false ? 1 : 0
  name                    = "${var.name_prefix}-nat-gw1-${random_string.suffix.result}"
  location                = var.arm_location
  resource_group_name     = data.azurerm_resource_group.selected.name
  idle_timeout_in_minutes = 10
}

data "azurerm_nat_gateway" "selected" {
  name                = var.byo_nat_gw == false ? azurerm_nat_gateway.nat-gw1.*.name[0]: var.byo_nat_gw_name
  resource_group_name = var.byo_nat_gw == false ? azurerm_nat_gateway.nat-gw1.*.resource_group_name[0] : var.byo_nat_gw_rg
}

# Associate Public IP to NAT Gateway
resource "azurerm_nat_gateway_public_ip_association" "nat-gw-association1" {
  count                = var.existing_nat_gw_pip_association == false ? 1 : 0
  nat_gateway_id       = data.azurerm_nat_gateway.selected.id
  public_ip_address_id = data.azurerm_public_ip.selected.id
}



# 2. CC VMs
# Create Cloud Connector Subnet
resource "azurerm_subnet" "cc-subnet" {
  count                = var.byo_subnet == false ? 1 : 0
  name                 = "${var.name_prefix}-ec-snet-${count.index+1}-${random_string.suffix.result}"
  resource_group_name  = var.byo_vnet == false ? data.azurerm_virtual_network.selected.resource_group_name : var.byo_vnet_subnets_rg_name
  virtual_network_name = var.byo_vnet == false ? data.azurerm_virtual_network.selected.name : var.byo_vnet_name
  address_prefixes     = [var.cc_subnet]
}

# Or reference an existing subnet
data "azurerm_subnet" "cc-selected" {
  name                 = var.byo_subnet == false ? azurerm_subnet.cc-subnet.*.name[0] : var.byo_cc_subnet_name
  resource_group_name  = var.byo_vnet == false ? data.azurerm_virtual_network.selected.resource_group_name : var.byo_vnet_subnets_rg_name
  virtual_network_name = var.byo_vnet == false ? data.azurerm_virtual_network.selected.name : var.byo_vnet_name
}


# Associate Cloud Connector Subnet to NAT Gateway
resource "azurerm_subnet_nat_gateway_association" "subnet-nat-association-ec" {
  count          = var.existing_nat_gw_subnet_association == false ? 1 : 0
  subnet_id      = data.azurerm_subnet.cc-selected.id
  nat_gateway_id = data.azurerm_nat_gateway.selected.id
}



# Cloud Connector Module variables
module "cc-vm" {
  cc_count                              = var.cc_count
  source                                = "../modules/terraform-zscc-lb-azure"
  name_prefix                           = var.name_prefix
  resource_tag                          = random_string.suffix.result
  resource_group                        = data.azurerm_resource_group.selected.name
  mgmt_subnet_id                        = data.azurerm_subnet.cc-selected.id
  service_subnet_id                     = data.azurerm_subnet.cc-selected.id
  ssh_key                               = tls_private_key.key.public_key_openssh
  cc_vm_managed_identity_name           = var.cc_vm_managed_identity_name
  cc_vm_managed_identity_resource_group = var.cc_vm_managed_identity_resource_group
  user_data                             = local.userdata
  http_probe_port                       = var.http_probe_port
  
  ccvm_instance_size                    = var.ccvm_instance_size
  ccvm_image_publisher                  = var.ccvm_image_publisher
  ccvm_image_offer                      = var.ccvm_image_offer
  ccvm_image_sku                        = var.ccvm_image_sku
  ccvm_image_version                    = var.ccvm_image_version

  depends_on = [
    local_file.user-data-file,
  ]
}



############################################################################################################################################
####### Legacy code for reference if customer desires to break cloud connector mgmt and service interfaces out into separate subnets #######
############################################################################################################################################

#resource "azurerm_subnet" "cc-mgmt-subnet" {
#  count                = var.byo_subnet == false ? 1 : 0
#  name                 = "${var.name_prefix}-ec-mgmt-snet-${count.index+1}-${random_string.suffix.result}"
#  resource_group_name  = var.byo_vnet == false ? data.azurerm_virtual_network.selected.resource_group_name : var.byo_vnet_subnets_rg_name
#  virtual_network_name = var.byo_vnet == false ? data.azurerm_virtual_network.selected.name : var.byo_vnet_name
#  address_prefixes     = [cidrsubnet(var.network_address_space, 12, (count.index*16)+3936)]
#}

# Or reference an existing subnet
#data "azurerm_subnet" "cc-mgmt-selected" {
#  name                 = var.byo_subnet == false ? azurerm_subnet.cc-mgmt-subnet.*.name[0] : var.byo_mgmt_subnet_name
#  resource_group_name  = var.byo_vnet == false ? data.azurerm_virtual_network.selected.resource_group_name : var.byo_vnet_subnets_rg_name
#  virtual_network_name = var.byo_vnet == false ? data.azurerm_virtual_network.selected.name : var.byo_vnet_name
#}

# Create Service Subnet
#resource "azurerm_subnet" "cc-service-subnet" {
#  count                = var.byo_subnet == false ? 1 : 0
#  name                 = "${var.name_prefix}-ec-service-snet-${count.index+1}-${random_string.suffix.result}"
#  resource_group_name  = var.byo_vnet == false ? data.azurerm_virtual_network.selected.resource_group_name : var.byo_vnet_subnets_rg_name
#  virtual_network_name = var.byo_vnet == false ? data.azurerm_virtual_network.selected.name : var.byo_vnet_name
#  address_prefixes     = [cidrsubnet(var.network_address_space, 12, (count.index*16)+4000)]
#}

# Or reference an existing subnet
#data "azurerm_subnet" "cc-service-selected" {
#  name                 = var.byo_subnet == false ? azurerm_subnet.cc-service-subnet.*.name[0] : var.byo_service_subnet_name
#  resource_group_name  = var.byo_vnet == false ? data.azurerm_virtual_network.selected.resource_group_name : var.byo_vnet_subnets_rg_name
#  virtual_network_name = var.byo_vnet == false ? data.azurerm_virtual_network.selected.name : var.byo_vnet_name
#}

# Associate Management Subnet to NAT Gateway
#resource "azurerm_subnet_nat_gateway_association" "subnet-nat-association-ec-mgmt" {
#  subnet_id      = var.byo_subnet == false ? azurerm_subnet.cc-mgmt-subnet.*.id[0] : data.azurerm_subnet.cc-mgmt-selected.*.id[0]
#  nat_gateway_id = azurerm_nat_gateway.nat-gw1.id
#}

# Associate Service Subnet to NAT Gateway
#resource "azurerm_subnet_nat_gateway_association" "subnet-nat-association-ec-service" {
#  subnet_id      = var.byo_subnet == false ? azurerm_subnet.cc-service-subnet.*.id[0] : data.azurerm_subnet.cc-service-selected.*.id[0]
#  nat_gateway_id = azurerm_nat_gateway.nat-gw1.id
#}
data "azurerm_subscription" "current-subscription" {
  subscription_id = "d46e73f1-7923-4fc4-97c6-ccbbe9b0e9e6"
}

data "azurerm_resource_group" "selected" {
  name = var.resource_group
}

data "azurerm_user_assigned_identity" "selected" {
  name                = var.cc_vm_managed_identity_name
  resource_group_name = var.cc_vm_managed_identity_resource_group
}


resource "azurerm_network_security_group" "cc-nsg" {
  name                = "${var.name_prefix}-cc-nsg-${var.resource_tag}"
  location            = data.azurerm_resource_group.selected.location
  resource_group_name = data.azurerm_resource_group.selected.name

  security_rule {
    name                       = "SSH_VNET"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ICMP_VNET"
    priority                   = 4001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "OUTBOUND"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "cc-service-nsg" {
  name                = "${var.name_prefix}-cc-service-nsg-${var.resource_tag}"
  location            = data.azurerm_resource_group.selected.location
  resource_group_name = data.azurerm_resource_group.selected.name
  
  security_rule {
    name                       = "ALL_VNET"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"  
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {              
    name                       = "OUTBOUND"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
}


resource "azurerm_network_interface" "cc-mgmt-nic" {
  count                     = var.cc_count
  name                      = "${var.name_prefix}-ccvm${count.index + 1}-mgmt-nic-${var.resource_tag}"
  location                  = data.azurerm_resource_group.selected.location
  resource_group_name       = data.azurerm_resource_group.selected.name

  ip_configuration {
    name                          = "${var.name_prefix}-cc-mgmt-nic-conf-${var.resource_tag}"
    subnet_id                     = var.mgmt_subnet_id
    private_ip_address_allocation = "dynamic"
    primary                       = true
    #public_ip_address_id          = azurerm_public_ip.ec-mgmt-pip.id
  }

}

resource "azurerm_network_interface_security_group_association" "ec-mgmt-nic-association" {
  count                     = var.cc_count
  network_interface_id      = azurerm_network_interface.cc-mgmt-nic[count.index].id
  network_security_group_id = azurerm_network_security_group.cc-nsg.id
}

resource "azurerm_network_interface" "cc-service-nic" {
  count                     = var.cc_count
  name                      = "${var.name_prefix}-ccvm${count.index + 1}-service-nic-${var.resource_tag}"
  location                  = data.azurerm_resource_group.selected.location
  resource_group_name       = data.azurerm_resource_group.selected.name
  enable_ip_forwarding      = true

  ip_configuration {
    name                          = "${var.name_prefix}-cc-service-nic-conf-${var.resource_tag}"
    subnet_id                     = var.service_subnet_id
    private_ip_address_allocation = "dynamic"
    primary                       = true
  }

  depends_on = [azurerm_network_interface.cc-mgmt-nic]
}

resource "azurerm_network_interface_security_group_association" "ec-service-nic-association" {
  count                     = var.cc_count
  network_interface_id      = azurerm_network_interface.cc-service-nic[count.index].id
  network_security_group_id = azurerm_network_security_group.cc-service-nsg.id
}

resource "azurerm_network_interface_backend_address_pool_association" "cc-vm-service-nic-lb-association" {
  count                   = var.cc_count
  network_interface_id    = azurerm_network_interface.cc-service-nic[count.index].id
  ip_configuration_name   = "${var.name_prefix}-cc-service-nic-conf-${var.resource_tag}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.cc-lb-backend-pool.id
}

resource "azurerm_linux_virtual_machine" "cc-vm" {
  count                        = var.cc_count
  name                         = "${var.name_prefix}-ccvm${count.index + 1}-${var.resource_tag}"
  location                     = data.azurerm_resource_group.selected.location
  resource_group_name          = data.azurerm_resource_group.selected.name
  size                         = var.ccvm_instance_size
  availability_set_id          = azurerm_availability_set.cc-availability-set.id
  network_interface_ids        = [
    azurerm_network_interface.cc-mgmt-nic[count.index].id,
    azurerm_network_interface.cc-service-nic[count.index].id
  ]

  computer_name                = "${var.name_prefix}-ccvm${count.index + 1}-${var.resource_tag}"
  admin_username               = var.cc_username
  custom_data                  = base64encode(var.user_data)

  admin_ssh_key {
    username   = var.cc_username
    public_key = "${trimspace(var.ssh_key)} ${var.cc_username}@me.io"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = var.ccvm_image_publisher
    offer     = var.ccvm_image_offer
    sku       = var.ccvm_image_sku
    version   = var.ccvm_image_version
  }

  plan {
    publisher = var.ccvm_image_publisher
    name      = var.ccvm_image_sku
    product   = var.ccvm_image_offer
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.selected.id]
  }

  depends_on = [
    azurerm_network_interface_security_group_association.ec-mgmt-nic-association,
    azurerm_network_interface_security_group_association.ec-service-nic-association
  ]
}

resource "azurerm_availability_set" "cc-availability-set" {
  name                         = "${var.name_prefix}-ccvm-availability-set-${var.resource_tag}"
  location                     = data.azurerm_resource_group.selected.location
  resource_group_name          = data.azurerm_resource_group.selected.name

}

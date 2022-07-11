#-----------------------------------------------------------------------------------------------------------------
# Create internal load balancer. Load balancer uses cloud connector service interfaces as its backend pool
# TCP 2200 health probes configured for backend pool member monitoring.

resource "azurerm_lb" "cc-lb" {
    name                        = "${var.name_prefix}-cc-lb-${var.resource_tag}"
  location                     = data.azurerm_resource_group.selected.location
  resource_group_name          = data.azurerm_resource_group.selected.name
  sku                          = "Standard"


  lifecycle {
    ignore_changes = [
      tags,
    ]
}
  
  
  frontend_ip_configuration {
    name                          = "${var.name_prefix}-cc-lb-ip-${var.resource_tag}"
    subnet_id                     = var.service_subnet_id
    private_ip_address_allocation = "Dynamic"
    #private_ip_address            = var.ilb_ip
  }
}

resource "azurerm_lb_backend_address_pool" "cc-lb-backend-pool" {
  name                = "${var.name_prefix}-cc-lb-backend-${var.resource_tag}"
  resource_group_name = data.azurerm_resource_group.selected.name
  loadbalancer_id     = azurerm_lb.cc-lb.id
}

resource "azurerm_lb_probe" "cc-lb-probe" {
  name                = "${var.name_prefix}-cc-lb-probe-${var.resource_tag}"
  resource_group_name = data.azurerm_resource_group.selected.name
  loadbalancer_id     = azurerm_lb.cc-lb.id
  protocol            = "Http"
  port                = var.http_probe_port 
  request_path        = "/?cchealth"
}


resource "azurerm_lb_rule" "cc-lb-rule" {
  name                           = "${var.name_prefix}-cc-lb-rule-${var.resource_tag}"
  resource_group_name            = data.azurerm_resource_group.selected.name
  loadbalancer_id                = azurerm_lb.cc-lb.id
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = azurerm_lb.cc-lb.frontend_ip_configuration[0].name
  backend_address_pool_id        = azurerm_lb_backend_address_pool.cc-lb-backend-pool.id
  probe_id                       = azurerm_lb_probe.cc-lb-probe.id
  load_distribution              = "SourceIP"
}
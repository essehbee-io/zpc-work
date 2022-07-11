## Create Azure ACR Registry

resource "azurerm_resource_group" "acr_rg" {
  name = "sb_acr_prod_rg"
  location = "East US"
}

resource "azurerm_container_registry" "acr_prod" {
  name = "sb_acr_prod"
  resource_group_name = azurerm_resource_group.acr_rg.name
  location = azurerm_resource_group.acr_rg.location
  sku = "Premium"
  admin_enabled = false
  public_network_access = "Enabled"
}
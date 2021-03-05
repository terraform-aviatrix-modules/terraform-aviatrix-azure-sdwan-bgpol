#SDWAN VNET
resource "aviatrix_vpc" "default" {
  cloud_type           = 8
  name                 = var.name
  region               = var.region
  cidr                 = var.cidr
  account_name         = var.account
  aviatrix_firenet_vpc = true
  aviatrix_transit_vpc = false
}

resource "azurerm_virtual_network_peering" "sdwan_to_transit" {
  name                      = "${var.name}-to-transit"
  resource_group_name       = var.transit_vnet.resource_group
  virtual_network_name      = aviatrix_vpc.default.azure_vnet_resource_id
  remote_virtual_network_id = var.transit_vnet.azure_vnet_resource_id
}

resource "azurerm_virtual_network_peering" "transit_to_sdwan" {
  name                      = "transit_to_${var.name}"
  resource_group_name       = var.transit_vnet.resource_group
  virtual_network_name      = var.transit_vnet.azure_vnet_resource_id
  remote_virtual_network_id = aviatrix_vpc.default.azure_vnet_resource_id
}
#SDWAN VNET
resource "aviatrix_vpc" "default" {
  cloud_type           = 8
  name                 = var.name
  region               = local.region
  cidr                 = var.cidr
  account_name         = local.account
  aviatrix_firenet_vpc = true
  aviatrix_transit_vpc = false
}

resource "aviatrix_azure_peer" "sdwan_transit_peering" {
  account_name1             = local.account
  account_name2             = var.transit_gw.account_name
  vnet_name_resource_group1 = aviatrix_vpc.default.vpc_id
  vnet_name_resource_group2 = var.transit_gw.vpc_id
  vnet_reg1                 = local.region
  vnet_reg2                 = var.transit_gw.vpc_reg
}

resource "aviatrix_transit_external_device_conn" "default" {
  vpc_id            = var.transit_gw.vpc_id
  connection_name   = "${var.name}-bgp-peering"
  gw_name           = var.transit_gw.gw_name
  connection_type   = "bgp"
  tunnel_protocol   = "LAN"
  bgp_local_as_num  = var.transit_gw.local_as_number
  bgp_remote_as_num = var.sdwan_as_number
  remote_lan_ip     = azurerm_network_interface.fgtport2.private_ip_address
  remote_vpc_name   = aviatrix_vpc.default.vpc_id

  depends_on = [aviatrix_azure_peer.sdwan_transit_peering, ]
}

resource "azurerm_route_table" "sdwan_to_transit" {
  name                          = "${var.name}-sdwan-transit"
  location                      = local.region
  resource_group_name           = aviatrix_vpc.default.resource_group
  disable_bgp_route_propagation = true

  route {
    name                   = "to_aviatrix"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = aviatrix_transit_external_device_conn.default.local_lan_ip
  }
}

resource "azurerm_route_table" "transit_to_sdwan" {
  name                          = "${var.name}-transit-sdwan"
  location                      = local.region
  resource_group_name           = split(":", var.transit_gw.vpc_id)[1]
  disable_bgp_route_propagation = true

  route {
    name                   = "to_sdwan"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_network_interface.fgtport2.private_ip_address
  }
}

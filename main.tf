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
  account_name1             = var.account
  account_name2             = local.account
  vnet_name_resource_group1 = aviatrix_vpc.default.vpc_id
  vnet_name_resource_group2 = var.transit_gw.vpc_id
  vnet_reg1                 = var.region
  vnet_reg2                 = local.region
}

resource "aviatrix_transit_external_device_conn" "default" {
  vpc_id            = var.transit_gw.vpc_id
  connection_name   = "${var.name}-bgp-peering"
  gw_name           = var.transit_gw.gw_name
  connection_type   = "bgp"
  tunnel_protocol   = "LAN"
  bgp_local_as_num  = var.transit_gw.local_as_number
  bgp_remote_as_num = var.sdwan_as_number
  remote_lan_ip     = "172.12.13.14"
  remote_vpc_name   = aviatrix_vpc.default.vpc_id
}
output "sdwan_pub_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}

output "connection_name" {
  value = aviatrix_transit_external_device_conn.default.connection_name
}

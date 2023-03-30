resource "azurerm_virtual_machine" "default" {
  name                         = "${var.name}-fgt"
  location                     = local.region
  resource_group_name          = aviatrix_vpc.default.resource_group
  network_interface_ids        = [azurerm_network_interface.fgtport1.id, azurerm_network_interface.fgtport2.id]
  primary_network_interface_id = azurerm_network_interface.fgtport1.id
  vm_size                      = var.instance_size

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = var.publisher
    offer     = var.fgtoffer
    sku       = var.license_type == "byol" ? var.fgtsku["byol"] : var.fgtsku["payg"]
    version   = var.fgtversion
  }

  plan {
    name      = var.license_type == "byol" ? var.fgtsku["byol"] : var.fgtsku["payg"]
    publisher = var.publisher
    product   = var.fgtoffer
  }

  storage_os_disk {
    name              = "osDisk"
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option     = "FromImage"
  }

  # Log data disks
  storage_data_disk {
    name              = "${var.name}-fgtvmdatadisk"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "30"
  }

  os_profile {
    computer_name  = "${var.name}-fgt"
    admin_username = var.username
    admin_password = var.password
    custom_data    = data.template_file.fgtvm.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  lifecycle {
    ignore_changes = [
      os_profile,
    ]
  }
}

data "template_file" "fgtvm" {
  template = templatefile("${path.module}/${var.template}.tpl", {
    hostname    = "SDWAN"
    bgp_peer    = aviatrix_transit_external_device_conn.default.local_lan_ip
    transit_asn = var.transit_gw.local_as_number
    sdwan_asn   = var.sdwan_as_number
    lan_gateway = cidrhost(aviatrix_vpc.default.public_subnets[2].cidr, 1)
  })
}

// Allocated Public IP
resource "azurerm_public_ip" "public_ip" {
  name                = "${var.name}-public-ip"
  location            = local.region
  resource_group_name = aviatrix_vpc.default.resource_group
  allocation_method   = "Static"
}

//  Network Security Group
resource "azurerm_network_security_group" "publicnetworknsg" {
  name                = "${var.name}-public-nsg"
  location            = local.region
  resource_group_name = aviatrix_vpc.default.resource_group

  security_rule {
    name                       = "All-In"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "All-Out"
    priority                   = 1001
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "privatenetworknsg" {
  name                = "${var.name}-private-nsg"
  location            = local.region
  resource_group_name = aviatrix_vpc.default.resource_group

  security_rule {
    name                       = "All-In"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "All-Out"
    priority                   = 1001
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

// FGT Network Interface port1
resource "azurerm_network_interface" "fgtport1" {
  name                 = "${var.name}-fgtport1"
  location             = local.region
  resource_group_name  = aviatrix_vpc.default.resource_group
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${var.name}-ipconfig1"
    subnet_id                     = aviatrix_vpc.default.public_subnets[0].subnet_id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_interface" "fgtport2" {
  name                 = "${var.name}-fgtport2"
  location             = local.region
  resource_group_name  = aviatrix_vpc.default.resource_group
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${var.name}-ipconfig1"
    subnet_id                     = aviatrix_vpc.default.public_subnets[2].subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# Connect the security group to the network interfaces
resource "azurerm_network_interface_security_group_association" "port1nsg" {
  network_interface_id      = azurerm_network_interface.fgtport1.id
  network_security_group_id = azurerm_network_security_group.publicnetworknsg.id
}

resource "azurerm_network_interface_security_group_association" "port2nsg" {
  network_interface_id      = azurerm_network_interface.fgtport2.id
  network_security_group_id = azurerm_network_security_group.privatenetworknsg.id
}

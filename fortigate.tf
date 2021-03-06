resource "azurerm_virtual_machine" "default" {
  name                         = "${var.name}-fgt"
  location                     = local.region
  resource_group_name          = aviatrix_vpc.default.resource_group
  network_interface_ids        = [azurerm_network_interface.fgtport1.id, azurerm_network_interface.fgtport2.id]
  primary_network_interface_id = azurerm_network_interface.fgtport1.id
  vm_size                      = var.instance_size
  storage_image_reference {
    publisher = "fortinet"
    offer     = "fortinet_fortigate-vm_v5"
    sku       = "fortinet_fg-vm_payg_20190624"
    version   = "6.2.3"
  }

  plan {
    name      = "fortinet_fg-vm_payg_20190624"
    publisher = "fortinet"
    product   = "fortinet_fortigate-vm_v5"
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

  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.fgtstorageaccount.primary_blob_endpoint
  }
}

data "template_file" "fgtvm" {
  template = file("fgt.conf")
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
    name                       = "TCP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
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
    name                       = "All"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_rule" "outgoing_public" {
  name                        = "egress"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = aviatrix_vpc.default.resource_group
  network_security_group_name = azurerm_network_security_group.publicnetworknsg.name
}

resource "azurerm_network_security_rule" "outgoing_private" {
  name                        = "egress-private"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = aviatrix_vpc.default.resource_group
  network_security_group_name = azurerm_network_security_group.privatenetworknsg.name
}

// FGT Network Interface port1
resource "azurerm_network_interface" "fgtport1" {
  name                = "${var.name}-fgtport1"
  location            = local.region
  resource_group_name = aviatrix_vpc.default.resource_group

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = aviatrix_vpc.default.public_subnets[0]
    private_ip_address_allocation = "static"
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_interface" "fgtport2" {
  name                = "${var.name}-fgtport2"
  location            = local.region
  resource_group_name = aviatrix_vpc.default.resource_group

  ip_configuration {
    name                          = "${var.name}-ipconfig1"
    subnet_id                     = aviatrix_vpc.default.private_subnets[0]
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
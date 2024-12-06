resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

##Create The Virtual Machine
resource "azurerm_public_ip" "public_ip" {
  name                = "agentip"
  resource_group_name = azurerm_resource_group.example.name
  location            = var.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "example" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}
resource "azurerm_network_security_group" "nsg" {
  name                = "ssh_nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "allow_ssh_sg"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow_publicIP"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  lifecycle {
    prevent_destroy = false
  }
}

resource "azurerm_network_interface_security_group_association" "association" {
  network_interface_id      = azurerm_network_interface.example.id
  network_security_group_id = azurerm_network_security_group.nsg.id

    depends_on = [azurerm_linux_virtual_machine.example]

}

resource "azurerm_linux_virtual_machine" "example" {
  name                = "${var.prefix}-machine"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
data "azurerm_public_ip" "public_ip" {
  name                = azurerm_public_ip.public_ip.name
  resource_group_name = azurerm_resource_group.example.name
  depends_on          = [azurerm_linux_virtual_machine.example]
}

output "ip_address" {
  value = data.azurerm_public_ip.public_ip.ip_address
}

## Install Docker and Configure Self-Hosted Agent
resource "null_resource" "install_docker" {
  provisioner "remote-exec" {
    inline = ["${file("\\script.sh")}"]
    #inline = ["${file("D:\\Nagarro\\Pramotions\\InfrastructureCode\\VM\\script.sh")}"]
    connection {
      type        = "ssh"
      user        = azurerm_linux_virtual_machine.example.admin_username
      private_key = file("~/.ssh/id_rsa")
      host        = data.azurerm_public_ip.public_ip.ip_address
      timeout     = "10m"
    }
  }
}
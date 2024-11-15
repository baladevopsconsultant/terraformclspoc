provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

# Create a Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

# Create a Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.rg_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create a Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.rg_name}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

#public IP resource
resource "azurerm_public_ip" "pip" {
 name = "${var.rg_name}-pip"
 location = azurerm_resource_group.rg.location
 resource_group_name = azurerm_resource_group.rg.name
 allocation_method = "Static"
# sku = "Basic"
}

# resource "null_resource" "get_ip" {
#  depends_on = [azurerm_public_ip.pip]
#  provisioner "local-exec" {
#   command = "echo ${azurerm_public_ip.pip.ip_address} > ip_address.txt"
#  }
#}

data "azurerm_public_ip" "pip" {
 name = azurerm_public_ip.pip.name
 resource_group_name = azurerm_public_ip.pip.resource_group_name
}

# Create a Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.rg_name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create a Security Rule to Allow SSH
resource "azurerm_network_security_rule" "ssh" {
  name                        = "allow-ssh"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# Create a Network Interface
resource "azurerm_network_interface" "nic" {
  name                = "${var.rg_name}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "example" {
 network_interface_id      = azurerm_network_interface.nic.id
 network_security_group_id = azurerm_network_security_group.nsg.id
}

# Create a Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "${var.rg_name}-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  disable_password_authentication = false
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 50
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

#  storage_data_disk {
#    name              = "${var.rg_name}-data-disk"
#    managed_disk_type = "Standard_LRS"
#    disk_size_gb      = 20
#    lun               = 0
#    caching           = "ReadWrite"
#  }
  provisioner "remote-exec" {
    inline = [ 
      "sudo apt-get update",
      "sudo apt-get -y install ansible"
    ]
    connection{
     type = "ssh"
     user = "${var.admin_username}"
     password = "${var.admin_password}"
     host = data.azurerm_public_ip.pip.ip_address
     timeout = "5m"
    }
  
}
  depends_on = [
   azurerm_public_ip.pip,
   azurerm_network_interface.nic
  ]
 provisioner "local-exec" {
    command = <<EOT
      echo '[vm]' > inventory
      echo '${data.azurerm_public_ip.pip.ip_address} ansible_user="${var.admin_username}" ansible_password="${var.admin_password}" ansible_ssh_common_args="-o StrictHostKeyChecking=no"' >> inventory
      ansible-playbook -i inventory playbook.yml
    EOT
  }
}

resource "azurerm_managed_disk" "tf-poc" {
 name = "tf-poc-disk-1"
 location =  azurerm_resource_group.rg.location
 resource_group_name = azurerm_resource_group.rg.name
 storage_account_type = "StandardSSD_LRS"
 create_option = "Empty"
 disk_size_gb = 20
}




# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY AN AZURE INSTANCE THAT RUNS A SIMPLE "HELLO, WORLD" WEB SERVER
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.80.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A RESOURCE GROUP
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_resource_group" "myterraformgroup" {
  name     = "terratest-${var.postfix}"
  location = var.location
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A VIRTUAL NETWORK RESOURCES
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_virtual_network" "myterraformnetwork" {
  name                = "vnet-${var.postfix}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.myterraformgroup.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name
}

resource "azurerm_subnet" "myterraformsubnet" {
  name                 = "subnet-${var.postfix}"
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "myterraformpublicip" {
  name                = "publicip-${var.postfix}"
  location            = azurerm_resource_group.myterraformgroup.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  allocation_method   = "Static"
}

#data "azurerm_public_ip" "example" {
#  name                = azurerm_public_ip.myterraformpublicip.name
#  resource_group_name = azurerm_resource_group.myterraformgroup.name
#}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE NETWORK SECURITY GROUP AND RULE
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_network_security_group" "myterraformnsg" {
  name                = "network-${var.postfix}"
  location            = azurerm_resource_group.myterraformgroup.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  security_rule {
    name                       = "HTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE NETWORK INTERFACE
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_network_interface" "myterraformnic" {
  name                = "nic-${var.postfix}"
  location            = azurerm_resource_group.myterraformgroup.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  ip_configuration {
    name                          = "nic-config-${var.postfix}"
    subnet_id                     = azurerm_subnet.myterraformsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Connect the security group to the network interface
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.myterraformnic.id
  network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm" {
  name                             = "vm-${var.postfix}"
  location                         = azurerm_resource_group.myterraformgroup.location
  resource_group_name              = azurerm_resource_group.myterraformgroup.name
  network_interface_ids            = [azurerm_network_interface.myterraformnic.id]
  vm_size                          = "Standard_B1s"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "terratestosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "vm-${var.postfix}"
    admin_username = var.username
    admin_password = random_password.main.result
    custom_data    = data.template_file.user_data.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  depends_on = [random_password.main]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE USER DATA SCRIPT THAT WILL RUN DURING BOOT ON THE INSTANCE
# ---------------------------------------------------------------------------------------------------------------------
data "template_file" "user_data" {
  template = file("${path.module}/user-data/user-data.sh")

  vars = {
    instance_text = var.instance_text
    instance_port = var.instance_port
  }
}

# Random password is used as an example to simplify the deployment and improve the security of the remote VM.
# This is not as a production recommendation as the password is stored in the Terraform state file.
resource "random_password" "main" {
  length           = 16
  override_special = "-_%@"
  min_upper        = "1"
  min_lower        = "1"
  min_numeric      = "1"
  min_special      = "1"
}

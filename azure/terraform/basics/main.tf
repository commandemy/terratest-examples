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
  #tenant_id       = "xxxxx"
  #subscription_id = "xxxxx"
  #client_id       = "xxxxx"
  #client_secret   = "xxxxx"
  features {}
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A RESOURCE GROUP
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = "terratest-${var.postfix}"
  location = var.location
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY VIRTUAL NETWORK RESOURCES
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.postfix}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
  name                 = "subnet-${var.postfix}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.17.0/24"]
}

resource "azurerm_network_interface" "main" {
  name                = "nic-${var.postfix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "terratestconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A VIRTUAL MACHINE RUNNING UBUNTU
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_virtual_machine" "main" {
  name                             = "vm-${var.postfix}"
  location                         = azurerm_resource_group.main.location
  resource_group_name              = azurerm_resource_group.main.name
  network_interface_ids            = [azurerm_network_interface.main.id]
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
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  depends_on = [random_password.main]
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

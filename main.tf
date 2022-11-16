terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }
}

  # Configure the Azure provider
  provider "azurerm" {
    features {}
  }
  
  # Test with pub ssh
  #resource "azurerm_ssh_public_key" "example" {
  #  name                = "${var.prefix}-key"
  #  resource_group_name = azurerm_resource_group.estudos_tf.name
  #  location            = azurerm_resource_group.estudos_tf.location
  #  public_key          = file("~/.ssh/terraform.pub")
  #}

  # Create (and display) an SSH key
  resource "tls_private_key" "ssh_key" {
    algorithm = "RSA"
    rsa_bits  = 4096
  }


  # Create a RG with var
  resource "azurerm_resource_group" "estudos_tf" {
    name     = "${var.prefix}-resources"
    location = var.location
  }

  # Create a VNet
  resource "azurerm_virtual_network" "vnet_tf" {
    name                = "${var.prefix}-network"
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.estudos_tf.location
    resource_group_name = azurerm_resource_group.estudos_tf.name
  }

  # Create a Subnet Internal
  resource "azurerm_subnet" "interna" {
    name                 = "interna"
    resource_group_name  = azurerm_resource_group.estudos_tf.name
    virtual_network_name = azurerm_virtual_network.vnet_tf.name
    address_prefixes     = ["10.0.2.0/24"]
  }

  # Create a IP Pub
  resource "azurerm_public_ip" "jenkins" {
    name                = "${var.prefix}-pip"
    resource_group_name = azurerm_resource_group.estudos_tf.name
    location            = azurerm_resource_group.estudos_tf.location
    allocation_method   = "Static"
  }

  # Create a Nic for Jenkins
  resource "azurerm_network_interface" "nic-jenkins" {
    name                = "${var.prefix}-nic"
    resource_group_name = azurerm_resource_group.estudos_tf.name
    location            = azurerm_resource_group.estudos_tf.location

    ip_configuration {
      name                          = "internal"
      subnet_id                     = azurerm_subnet.interna.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id          = azurerm_public_ip.jenkins.id
    }
  }

  # Create a VM Ubuntu with key_ssh
  resource "azurerm_linux_virtual_machine" "jenkins" {
    name                = "${var.prefix}-vm"
    resource_group_name = azurerm_resource_group.estudos_tf.name
    location            = azurerm_resource_group.estudos_tf.location
    size                = "Standard_B2s"
    admin_username      = "casamento"
  # admin_password      = "P@ssw0rd1234!"
    admin_ssh_key {
    username   = "casamento"
  # public_key = file("~/.ssh/id_rsa.pub")
    public_key = tls_private_key.ssh_key.public_key_openssh
    }
    disable_password_authentication = true
    network_interface_ids = [
      azurerm_network_interface.nic-jenkins.id,
    ]

    source_image_reference {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-focal"
      sku       = "20_04-lts-gen2"
      version   = "latest"
    }

    os_disk {
      storage_account_type = "Standard_LRS"
      caching              = "ReadWrite"
    }

  # provisioner "remote-exec" {
  #   inline = [
  #     "ls -la /tmp",
  #   ]
  # connection {
  #     host     = self.public_ip_address
  #     user     = self.admin_username
  #     public_key = file("~/.ssh/id_rsa.pub")
  #   }
  # }
  }
 
  # Create cluster kubernetes
  resource "azurerm_kubernetes_cluster" "k8s" {
    name                = "${var.prefix}-k8s"
    location            = azurerm_resource_group.estudos_tf.location
    resource_group_name = azurerm_resource_group.estudos_tf.name
    dns_prefix          = "${var.prefix}-k8s"
    default_node_pool {
      name       = "dfltworker"
      node_count = 2
      vm_size    = "Standard_DS2_v2"
    }
    identity {
      type = "SystemAssigned"
    }
    tags = {
      environment = "Estudo-Tf"
    }
  }
provider "azurerm" {
    features {}
    client_id       = "${var.client_id}"
    client_secret   = "${var.client_secret}"
    subscription_id = "${var.subscription_id}"
    tenant_id       = "${var.tenant_id}"
}

// Resource group
data "azurerm_resource_group" "main" {
    name     = var.resourcegroup
}

// Virtual network
resource "azurerm_virtual_network" "main" {
    name                    = "${var.prefix}-network"
    address_space           = ["10.0.0.0/22"]
    location                = data.azurerm_resource_group.main.location
    resource_group_name     = data.azurerm_resource_group.main.name
    tags                    = var.tags
}

// Internal subnet for the upper vnet
resource "azurerm_subnet" "internal" {
    name                    = "internal"
    resource_group_name     = data.azurerm_resource_group.main.name
    virtual_network_name    = azurerm_virtual_network.main.name
    address_prefixes        = ["10.0.2.0/24"]
}

// Network security group
resource "azurerm_network_security_group" "main" {
    name                    = "${var.prefix}-nsg"
    location                = data.azurerm_resource_group.main.location
    resource_group_name     = data.azurerm_resource_group.main.name
    tags                    = var.tags
}

// Allow only acces to VMs on the same subnet
resource "azurerm_network_security_rule" "rule1" {
    name                       = "allow-internal"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.0.0/24"
    destination_address_prefix = "*"
    description                = "description-ssh"
    resource_group_name         = data.azurerm_resource_group.main.name
    network_security_group_name = azurerm_network_security_group.main.name
}

// Deny all access from the internet
resource "azurerm_network_security_rule" "rule2" {
    name                       = "deny-internet"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.0.0/24"  
    resource_group_name         = data.azurerm_resource_group.main.name
    network_security_group_name = azurerm_network_security_group.main.name
}

// Network interface group
resource "azurerm_network_interface" "main" {
    name                = "${var.prefix}-nic${count.index}"
    location            = data.azurerm_resource_group.main.location
    resource_group_name = data.azurerm_resource_group.main.name
    count               = var.vm_count
      ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    }  
    tags                          = var.tags
}

// Public IP
resource "azurerm_public_ip" "main" {
    name                = "${var.prefix}-pubip"
    location            = data.azurerm_resource_group.main.location
    resource_group_name = data.azurerm_resource_group.main.name
    allocation_method   = "Dynamic"
    sku                 = "Basic" 
    tags                = var.tags
}

// Load balancer
resource "azurerm_lb" "main" {
    name                = "${var.prefix}-lb"
    location            = data.azurerm_resource_group.main.location
    resource_group_name = data.azurerm_resource_group.main.name

    frontend_ip_configuration {
        name                 = "${var.prefix}-load-balancer-frontend"
        public_ip_address_id = azurerm_public_ip.main.id
    }

    tags                     = var.tags
}

// Load balancer backend address pool
resource "azurerm_lb_backend_address_pool" "main" {
    loadbalancer_id = azurerm_lb.main.id
    name            = "backend-adress-pool"
}

// Load balancer backend network address pool association
resource "azurerm_network_interface_backend_address_pool_association" "main" {
    count                   = var.vm_count
    network_interface_id    = element(azurerm_network_interface.main.*.id, count.index)
    ip_configuration_name   = "internal"
    backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

// VM availability set
resource "azurerm_availability_set" "main" {
    name                = "${var.prefix}-availset"
    location            = data.azurerm_resource_group.main.location
    resource_group_name = data.azurerm_resource_group.main.name
    tags                = var.tags
}

// Creation of virtual machines
data "azurerm_image" "main" {
    name            = "PackerImage"
    resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_linux_virtual_machine" "main" {
    count                           = var.vm_count       
    name                            = "${var.prefix}-vm${count.index}" 
    resource_group_name             = data.azurerm_resource_group.main.name
    location                        = data.azurerm_resource_group.main.location
    size                            = "Standard_D2s_v3"
    admin_username                  = "${var.username}"
    admin_password                  = "${var.password}"
    disable_password_authentication = false
    availability_set_id             = azurerm_availability_set.main.id
    network_interface_ids = [element(azurerm_network_interface.main.*.id, count.index),]

    os_disk {
        storage_account_type = "Standard_LRS"
        caching              = "ReadWrite"
    }

    tags                     = var.tags

    source_image_id = data.azurerm_image.main.id
}

// Managed disks creation
resource "azurerm_managed_disk" "main" {
    count                = var.vm_count
    name                 = "${var.prefix}-managed-disk-${count.index}"
    location             = data.azurerm_resource_group.main.location
    resource_group_name  = data.azurerm_resource_group.main.name
    storage_account_type = "Standard_LRS"
    create_option        = "Empty"
    disk_size_gb         = "1"
    tags                 = var.tags
}
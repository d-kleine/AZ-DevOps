resource "azurerm_network_interface" "example_nic" {
  name                = "${var.application_type}-${var.resource_type}-nic"
  location            = var.location
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.public_ip_address_id
  }
}

resource "azurerm_linux_virtual_machine" "example_vm" {
  name                = "${var.application_type}-${var.resource_type}"
  location            = var.location
  resource_group_name = var.resource_group
  size                = "Standard_DS2_v2"
  admin_username      = var.vm_admin_username
  network_interface_ids = [azurerm_network_interface.example_nic.id]
  source_image_id       = var.packer_image
  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCzAviodD+9m+UBML5VYfYU5hygdXx/yblV2cvu857B8P4p2BTgVm2LUl+IyB9Su8r9yVQsooZXpZ1T61iyv4LyWgRo0zAJfl5qkm7xKmHwrL4k8ebe2QhEeX9zJZYFHjbVbxjHiForOWRB6RbBYoDU7W+ZCrLay2oPTqV6Mdppluw7MwPUEwz9IIsczsOXFeNwSyeG9C9HrXXDZpjB6FUPlUehXMM2fCu2d3wf0Rj7OyfstVWuLIFT62QSX+Wk2QV2eh3dZikFjglxwISx8swRYSF5qCrOxprq8EMCg/pQ5rtxTgWXDfZcn6lTo6afx+NlJiM44LQIoHOXlpYOaSeI6+LDvx3M2FzJN/Vi5KO997imJ7BEpCZGBtRB/RsGRpRg08joWJQvm9PozO0p0O5qN+EROP7+rWSLkAeoG5JwMzv61WGcBvtWB35Q6SnfX+l5EPrtYGs+G8Rwyl23SVnuBIfydaoFRLDpqWu2+nAuisRY+5StQVUu7+UnsIqS76k= odl_user@SandboxHost-638359771865329110"
  }
  os_disk {
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "18.04-LTS"
#     version   = "latest"
#   }
}

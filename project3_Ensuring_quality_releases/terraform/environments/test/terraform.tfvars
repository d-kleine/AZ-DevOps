# Azure subscription vars
subscription_id = "481b1dfa-09f6-4305-a978-b656e03d8e84" # service principal id
tenant_id = "f958e84a-92b8-439f-a62d-4f45996b6d07"
client_id = "d2dd769d-b199-45f8-b733-d9a218d1fbd3" # application id
client_secret = "5JO8Q~iOJjNrbQxGLjX2XFaJt_g35Eds.gzh3bl2" # secret key

# Resource Group/Location
location = "westeurope"
resource_group = "Azuredevops"
application_type = "project-qa"

# Network
virtual_network_name = "udacity-ensuring-quality-releases-vnet"
address_space = ["10.5.0.0/16"]
address_prefix_test = "10.5.1.0/24"

# VM
vm_admin_username = "adminuser"
packer_image = "/subscriptions/481b1dfa-09f6-4305-a978-b656e03d8e84/resourceGroups/Azuredevops/providers/Microsoft.Compute/images/packer-image"
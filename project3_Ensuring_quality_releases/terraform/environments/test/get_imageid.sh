#!/bin/bash
# Set your Azure subscription ID and resource group name
subscription_id="481b1dfa-09f6-4305-a978-b656e03d8e84"
resource_group="Azuredevops"
image_name="packer-image"

# Get the image ID
image_id=$(az image show --subscription $subscription_id --resource-group $resource_group --name $image_name --query id --output tsv)

# Display the image ID
echo "Source Image ID: $image_id"
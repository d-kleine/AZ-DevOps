variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default = "azdevops"
}

variable "resourcegroup" {
  description = "Enter name of the resource group "
  default = "Azuredevops"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default = "West Europe" 
}

variable "tenant_id" {
    description = "Tenant ID"
    default = "f958e84a-92b8-439f-a62d-4f45996b6d07"
}

variable "client_id" {  
    description = "Client ID"
    default = "752c4152-7514-463b-bdba-7b977e3f8fbe"
}

variable "client_secret" {  
    description = "Client secret id"
    default = "SdD8Q~QOdQU3np190XSMAZljfyq0~wxICoSDwcZY"
}

variable "subscription_id" {  
    description = "Azure subscription id"
    default = "df56a173-611b-429d-901a-af369d7d59b5"
}

variable "vm_count" {
  description = "Number of virtual machines to deploy"
  type        = number
  default     = 2
}

variable "deployment_name" {
  description = "Name of the deployment"
  type        = string
  default     = "packer-deployment"
}

variable "password" {
    description = "The Azure resource password"
    default = "P@ssw0rd1234!" 
    sensitive = true
}

variable "username" {
    description = "The Azure admin username"
    default     = "adminuser" 
    sensitive   = true
}

variable "tags" {
  type = map
  default = {
    project = "udacity-webserver"
  }
}
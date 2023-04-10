variable "appname" {
  type        = string
  default     = "myapp"
  description = "name of the Application that is used to prefix with the Azure resources"
}

variable "suffix" {
  type        = string
  default     = "01"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "env" {
  type        = string
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}
variable "resource_group_location" {
  type        = string
  default     = "westeurope"
  description = "Location of the resource group."
}

#variable "resource_group_name" {
#  type        = string
#  default     = "rg-myapp-dev-01"
#  description = "Prefix of the resource group name unique in your Azure subscription."
#}

variable "container_registry_name" {
  type        = string
  description = "Name of the azure container registry"
}

variable "container_registry_sku" {
  type        = string
  default = "Standard"
  description = "Name of the azure container registry"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the azure storage account"
}

variable "storage_account_tier" {
  type        = string
  default = "Standard"
  description = "Storage account tier"
}

variable "storage_account_replication_type" {
  type        = string
  default = "LRS"
  description = "Storage account replication type"
}

variable "storage_account_container_name" {
  type        = string
  description = "Storage account container name"
}

variable "storage_account_container_access_type" {
  type        = string
  default = "private"
  description = "Storage account container access type"
}

variable "sa_net_rules_default_action" {
  type        = string
  default = "Allow"
  description = "Default action for the storage account network rules"
}

variable "vnet" {
  type        = string
  description = "Name of the virtual network to create in the Resource Group"
}

#variable "vnet_address_space" {
#  type        = string
#  default     = "10.0.0.0/16"
#  description = "IP range for the vnet"
#}

variable "subnet" {
  type        = string
  description = "Name of the Subnet to associate with the VNet"
}

#variable "subnet_address_prefixes" {
#  type        = string
#  default     = "10.0.1.0/24"
#  description = "IP range for the Subnet"
#}

#variable "subnet_service_endpoints" {
#  type        = string
#  default     = "Microsoft.Storage"
#  description = "Name of the Service endpoint that needs to be associated with the subnet"
#}

variable "nsg" {
  type        = string
  description = "Name of the Network Security Group to be created in the Resource Group"
}

variable "app_service_plan" {
  type        = string
  description = "Name of the App Service Plan to be created for the Functions App"
}

variable "asp_os_type" {
  type        = string
  default = "Linux"
  description = "Operating System for the App Service Plan"
}

variable "asp_sku_unit" {
  type        = string
  default = "EP1"
  description = "Operating System for the App Service Plan"
}

variable "azure_function_app" {
  type        = string
  description = "Name of the Functions App to be created in the Resource Group"
}

variable "docker_image_name" {
  type        = string
  description = "Name of the Docker Image"
}

variable "docker_image_tag" {
  type        = string
  default     = "latest"
  description = "Version of the docker image"
}

variable "function_app_slot_name" {
  type        = string
  description = "Name of the Function App slot"
}
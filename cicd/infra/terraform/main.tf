
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.appname}-${var.env}-${var.suffix}"
  location = var.resource_group_location
}

resource "azurerm_container_registry" "acr" {
  name                = "${var.container_registry_name}${var.appname}${var.env}${var.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = var.container_registry_sku
  admin_enabled       = true
  depends_on = [
    azurerm_resource_group.rg
  ]
}
resource "azurerm_storage_account" "sa" {
  name                     = "${var.storage_account_name}${var.appname}${var.env}${var.suffix}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  allow_nested_items_to_be_public = false
  # Needs to be public accessable due to Function App usage
  public_network_access_enabled = true
  cross_tenant_replication_enabled = false

  # Common CCC accepted policy exception for storage account used only by Azure App Functions
  tags = {
    AcceptedException_storage-H-004 = "AcceptedException_storage-H-004"
  }
  depends_on = [
    azurerm_resource_group.rg
  ]
}

resource "azurerm_storage_container" "sa-container" {
  name                  = "${var.storage_account_container_name}${var.appname}${var.env}${var.suffix}"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = var.storage_account_container_access_type
}

resource "azurerm_storage_account_network_rules" "sa-net-rules" {
  storage_account_id   = azurerm_storage_account.sa.id

  default_action = var.sa_net_rules_default_action
  virtual_network_subnet_ids = [azurerm_subnet.subnet.id]
  depends_on = [
    azurerm_storage_container.sa-container
  ]
}
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.vnet}${var.appname}${var.env}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.subnet}${var.appname}${var.env}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Create a network security group to restrict access to the storage account
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.nsg}${var.appname}${var.env}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowFunctionAppAccess"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "10.0.1.0/24"  # Allow access from the Function App subnet
    destination_address_prefix = "*"  # Restrict access to the storage account
  }
  depends_on = [
    azurerm_storage_account.sa
  ]
}

resource "azurerm_service_plan" "asp" {
  name                = "${var.app_service_plan}${var.appname}${var.env}${var.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = var.asp_os_type
  sku_name            = var.asp_sku_unit
}

resource "azurerm_linux_function_app" "fn-app" {
  name                       = "${var.azure_function_app}${var.appname}${var.env}${var.suffix}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  service_plan_id            = azurerm_service_plan.asp.id
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key

  client_certificate_enabled        = false

  https_only                        = true
  builtin_logging_enabled           = false
  # Vnet intergration for Azure BackBone traffic
  virtual_network_subnet_id = azurerm_subnet.subnet.id

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_network_security_group.nsg,
    azurerm_storage_account.sa
  ]

  app_settings = {
#    FUNCTIONS_EXTENSION_VERSION               = "~2"
#    "DOCKER_REGISTRY_SERVER_URL" = "https://${azurerm_container_registry.acr.login_server}"
#    "DOCKER_REGISTRY_SERVER_USERNAME" = azurerm_container_registry.acr.admin_username
#    "DOCKER_REGISTRY_SERVER_PASSWORD" = azurerm_container_registry.acr.admin_password
#    "WEBSITE_RUN_FROM_PACKAGE" = 1
#    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING  = azurerm_storage_account.sa.primary_connection_string
#    WEBSITE_CONTENTSHARE                      = azurerm_storage_account.sa.name
#    WEBSITE_CONTENTOVERVNET = 1
  }

  site_config {
    container_registry_use_managed_identity = true
    application_stack {
      docker {
        registry_url = "https://${azurerm_container_registry.acr.login_server}"
        image_name = var.docker_image_name
        image_tag = var.docker_image_tag
      }
    }
  }
}

#To test another application, this slot can be used without touching the production slot in the Function App
resource "azurerm_linux_function_app_slot" "fn-app-slot" {
  name                 = "${var.function_app_slot_name}${var.appname}${var.env}${var.suffix}"
  function_app_id      = azurerm_linux_function_app.fn-app.id
  storage_account_name = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  site_config {}
}

#resource "null_resource" "docker_push" {
#  provisioner "local-exec" {
#    command = <<-EOT
#        docker login ${azurerm_container_registry.acr.login_server}
#        docker push ${azurerm_container_registry.acr.login_server}
#      EOT
#  }
#}
#az functionapp config container set --docker-custom-image-name <container registry name> --docker-registry-server-url https://<Registry Name>.azurecr.io  --name <functionApp> --resource-group <resourcegroupName>
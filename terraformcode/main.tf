provider "azurerm" {
 features {}
 resource_provider_registrations = "none"
}

resource "azurerm_resource_group" "rg" {
 name = "east-us-rg"
 location = "eastus"
}



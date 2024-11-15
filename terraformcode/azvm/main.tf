terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"  // Replace with your desired version constraint
    }
  }
}
provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

module "rg_vm" {
  source          = "./modules/rg_vm"
  rg_name         = "tf-poc-rg"
  location        = "East Asia"
  admin_username  = "adminuser"
  admin_password  = "terraformpoc@1234"
}

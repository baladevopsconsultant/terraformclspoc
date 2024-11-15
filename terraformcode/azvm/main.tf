provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

module "rg_vm" {
  source          = "./modules/rg_vm"
  rg_name         = "tf-poc-rg"
  location        = "Central India"
  admin_username  = "adminuser"
  admin_password  = "terraformpoc@1234"
}

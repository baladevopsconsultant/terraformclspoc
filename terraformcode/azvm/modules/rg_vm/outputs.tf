output "rg_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "vm_id" {
  description = "The ID of the virtual machine"
  value       = azurerm_linux_virtual_machine.vm.id
}

output "public_ip" {
  description = "The public IP address of the virtual machine"
  value       = azurerm_public_ip.pip.ip_address
}

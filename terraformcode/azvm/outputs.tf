output "rg_name" {
  description = "The name of the resource group"
  value       = module.rg_vm.rg_name
}

output "vm_id" {
  description = "The ID of the virtual machine"
  value       = module.rg_vm.vm_id
}

output "public_ip" {
  description = "The public IP address of the virtual machine"
  value       = module.rg_vm.public_ip
}


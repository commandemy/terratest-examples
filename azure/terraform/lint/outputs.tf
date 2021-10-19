output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "vm_name" {
  value = azurerm_virtual_machine.main.name
}

output "disk_name" {
  value = azurerm_virtual_machine.main.storage_os_disk[0].name
}

output "image_version" {
  value = azurerm_virtual_machine.main.storage_image_reference.*.sku[0]
}

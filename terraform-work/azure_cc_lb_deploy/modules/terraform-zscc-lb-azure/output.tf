output "private-ip" {
  value = azurerm_network_interface.cc-mgmt-nic.*.private_ip_address
}

output "service-ip" {
  value = azurerm_network_interface.cc-service-nic.*.private_ip_address
}

output "cc-hostname" {
  value = azurerm_linux_virtual_machine.cc-vm.*.computer_name
}

output "lb-ip" {
  value = azurerm_lb.cc-lb.private_ip_address
}

output "lb-backend-address-pool" {
  value = azurerm_lb_backend_address_pool.cc-lb-backend-pool.id
}
#output "cc-pid" {
#  value = azurerm_linux_virtual_machine.cc-vm[count.index].identity.*.principal_id
#}
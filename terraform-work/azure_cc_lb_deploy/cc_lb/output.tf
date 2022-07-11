locals {

  testbedconfig = <<TB

Resource Group : ${data.azurerm_resource_group.selected.name}
LB IP          : ${module.cc-vm.lb-ip}
CC VM1 Mgmt IP : ${module.cc-vm.private-ip[0]}
CC VM1 Svc IP  : ${module.cc-vm.service-ip[0]}
CC VM2 Mgmt IP : ${module.cc-vm.private-ip[1]}
CC VM2 Svc IP  : ${module.cc-vm.service-ip[1]}
NAT GW IP      : ${data.azurerm_public_ip.selected.ip_address}

TB

testbedconfigpyats = <<TBP
testbed:
  name: azure-${random_string.suffix.result}

  EC1:
    os: linux
    type: linux
    connections:
      defaults:
        class: fast.connections.pyats_connector.ZSNodeConnector
        via: fast
      fast:
        name: /sc/instances/edgeconnector0
        hostname: ${module.cc-vm.private-ip[0]}
        port: 22
        username: zsroot
        key_filename: ${var.name_prefix}-key-${random_string.suffix.result}.pem
  EC2:
    os: linux
    type: linux
    connections:
      defaults:
        class: fast.connections.pyats_connector.ZSNodeConnector
        via: fast
      fast:
        name: /sc/instances/edgeconnector0
        hostname: ${module.cc-vm.private-ip[1]}
        port: 22
        username: zsroot
        key_filename: ${var.name_prefix}-key-${random_string.suffix.result}.pem
TBP
}

output "testbedconfig" {
  value = local.testbedconfig
}

resource "local_file" "testbed" {
  content = local.testbedconfigpyats
  filename = "testbed.yml"
}
## This is only a sample terraform.tfvars file.
## Uncomment and change the below variables according to your specific environment
## Steps 1-5 required for Cloud Connector (base_cc base_cc_lb or cc_lb) deployments

#####################################################################################################################
                  ##### Cloud Init Provisioning variables for userdata file  #####
#####################################################################################################################
## 1. Zscaler Cloud Connector Provisioning URL E.g. connector.zscalerbeta.net/wapi/v1/provUrl?name=azure_prov_url

cc_vm_prov_url                         = "connector.zscalerbeta.net/api/v1/provUrl?name=logan_sbx_azure"

## 2. Azure Vault URL E.g. "https://zscaler-cc-demo.vault.azure.net"

azure_vault_url                        =  "https://logan-tf-kv.vault.azure.net/"

## 3. Cloud Connector cloud init provisioning listener port. This is required for Azure LB Health Probe deployments. 
## Uncomment and set custom probe port to a single value of 80 or any number between 1024-65535. Default is 0/null.

http_probe_port                        = 50000

#####################################################################################################################
                ##### Prerequisite Provisioned Managed Identity Resource and Resource Group  #####
                ##### Managed Identity should have GET/LIST access to Key Vault Secrets and  #####
                ##### Network Contributor Role Assignment to Subscription or RG where Cloud  #####
                ##### Connectors will be provisioned prior to terraform deployment.          #####
                ##### (minimum Role permissions: Microsoft.Network/networkInterfaces/read)   ##### 
#####################################################################################################################

## 4. Provide your existing Azure Managed Identity name to attach to the CC VM. E.g cloud_connector_managed_identity

cc_vm_managed_identity_name             = "logan-tf-cc"

## 5. Provide the existing Resource Group of the Azure Managed Identity name to attach to the CC VM. E.g. cloud_connector_rg_1

cc_vm_managed_identity_resource_group   = "logan_tf_deploy_brownfield"


#####################################################################################################################
                ##### Custom variables. Only change if required for your environment  #####
#####################################################################################################################

## 6. Cloud Connector VNET address space. (Minimum /27 required. Default: 10.1.0.0/16)

network_address_space                 = "10.1.0.0/16"

## 7. Cloud Connector Subnet space. (Minimum /28 required. Default: 10.1.100.0/24 within VNET 10.1.0.0/16).
##    Uncomment and modify if byo_vnet is set to true AND you want terraform to create a NEW subnet for Cloud Connector
##    in that existing VNET. OR if you choose to modify the address space in the newly created VNET via network_address_space variable change
##    CIDR and mask must be a valid value available within VNET.

cc_subnet                             = "10.1.150.0/24"

## 7. Number of Cloud Connectors to be provisioned behind Azure LB deployment. Only limitation is available IP space
##    in subnet configuration. Default count is 2 for base_cc_lb and cc_lb. Default CC subnet is /24 so 250 CC max

cc_count                              = 2

## 8. Number of Workload VMs to be provisioned in server subnet. Only limitation is available IP space
##    in subnet configuration. Default count is 2 for base_cc_lb. Default server subnet is /24 so 250 max

vm_count                              = 2



#####################################################################################################################
      ##### Custom BYO variables. Only applicable for "cc_lb" deployment without "base" resource requirements  #####
#####################################################################################################################

## 9. By default, this script will create a new Resource Group and place all resources in this group.
##     Uncomment if you want to deploy all resources in an existing Resource Group? (true or false. Default: false)

byo_rg                                   = true

## 10. Provide your existing Resource Group name. Only uncomment and modify if you set byo_rg to true

byo_rg_name                              = "logan_tf_deploy_brownfield"

## 11. By default, this script will create a new Azure Virtual Network in the default resource group.
##     Uncomment if you want to deploy all resources to a VNET that already exists (true or false. Default: false)

byo_vnet                                = true

## 12. Provide your existing VNET name. Only uncomment and modify if you set byo_vnet to true

byo_vnet_name                           = "lf_cc_sbx"

## 13. Provide the existing Resource Group name of your VNET. Only uncomment and modify if you set byo_vnet to true
##     Subnets depend on VNET so the same resource group is implied for subnets

byo_vnet_subnets_rg_name                = "logan_tf_deploy_brownfield"

## 14. By default, this script will create a new Azure subnet in the default resource group.
##     Uncomment if you want to deploy all resources in subnets that already exist (true or false. Default: false)
##     Dependencies require in order to reference existing subnets, the corresponding VNET must also already exist.
##     Setting byo_subnet to true means byo_vnet must ALSO be set to true.

byo_subnet                             = true

## 15. Provide your existing Cloud Connector subnet name. Only uncomment and modify if you set byo_subnet to true

byo_cc_subnet_name                     = "cloudconnector"

## 16. By default, this script will create a new Public IP resource to be associated with CC NAT Gateay.
##    Uncomment if you want to use your own public IP for the NAT GW (true or false. Default: false)

byo_pip_address                       = true

## 17. Provide your existing Azure Public IP resource name. Only uncomment and modify if you set byo_pip_address to true
##     Existing Public IP resource cannot be associated with any resource other than an existing NAT Gateway in which
##     case existing_pip_association and existing_nat_gw_association need both set to true

byo_pip_name                          = "logan_public_tf"

## 18. Provide the existing Resource Group name of your Azure public IP.  Only uncomment and modify if you set byo_pip_address to true

byo_pip_rg                            = "logan_tf_deploy_brownfield"

## 19. By default, this script will create a new NAT Gateway resource fpr the Cloud Connector subnet to be associated
##    Uncomment if you want to use your own NAT GW (true or false. Default: false)

byo_nat_gw                             = true

## 20. Provide your existing Azure NAT Gateway resource name. Only uncomment and modify if you set byo_nat_gw to true

byo_nat_gw_name                          = "logan_tf_ngw"

## 21. Provide the existing Resource Group name of your Azure public IP.  Only uncomment and modify if you set byo_nat_gateway to true

byo_nat_gw_rg                            = "logan_tf_deploy_brownfield"

## 22. By default, this script will create a new Azure Public IP and associate it with a new/existing NAT Gateway.
##  Uncomment if you are deploying cloud connector to an environment where the subnet already exists AND is already asssociated to
##  an existing NAT Gateway. (true or false. Default: false). 
##  Setting existing_pip_association to true means byo_nat_gw and byo_pip_address must ALSO be set to true.

existing_nat_gw_pip_association                    = true

##  23. By default this script will create a new Azure NAT Gateway and associate it with a new or existing subnet.
##  Uncomment if you are deploying cloud connector to an environment where the subnet already exists AND is already asssociated to
##  an existing NAT Gateway. (true or false. Default: false). 
##  Setting existing_nat_gw_association to true means byo_subnet AND byo_nat_gw must also be set to true.

existing_nat_gw_subnet_association                   = true
variable "name_prefix" {
  description = "A prefix to associate to all the module resources"
  default     = "zs"
}

variable "resource_tag" {
  description = "A tag to associate to all the module resources"
  default     = "cloud-connector"
}

variable "deployment_tag" {
  description = "A deployment tag to associate to all the module resources"
  default     = "development"
}

variable "resource_group" {
  description = "Main Resource Group Name"
}


#### Script module by default pushes the same single subnet ID for both mgmt_subnet_id and service_subnet_id, so they are effectively the same variable
#### leaving each as unique values should customer choose to deploy mgmt and service as individual subnets for additional isolation
variable "mgmt_subnet_id" {
  description = "Cloud Connector management subnet id. "
}

variable "service_subnet_id" {
  description = "Cloud Connector service subnet id"
}

variable "cc_username" {
  description = "Default Cloud Connector admin/root username"
  default   = "zsroot"
  type      = string
}

variable "ssh_key" {
  description = "SSH Key for instances"
}

variable "ccvm_instance_size" {
  description = "Cloud Connector Image size"
  default     = "Standard_D2s_v3"
  validation {
          condition     = ( 
            var.ccvm_instance_size == "Standard_D2s_v3"
          )
          error_message = "Input ccvm_instance_size must be set to an approved vm size."
      }
}

variable "user_data" {
  description = "Cloud Init data"
}

variable "cc_vm_managed_identity_name" {
  description = "Managed identity to be assigned to the CC VM"
}

variable "cc_vm_managed_identity_resource_group" {
  description = "Resource group of managed identity to be assigned to the CC VM"
}

variable "ccvm_image_publisher" {
  description = "Azure Marketplace Cloud Connector Image Publisher"
  default     = "zscaler1579058425289"
}

variable "ccvm_image_offer" {
  description = "Azure Marketplace Cloud Connector Image Offer"
  default     = "zia_cloud_connector"
}

variable "ccvm_image_sku" {
  description = "Azure Marketplace Cloud Connector Image SKU"
  default     = "zs_ser_cc_03"
}

variable "ccvm_image_version" {
  description = "Azure Marketplace Cloud Connector Image Version"
  default     = "latest"
}

variable "cc_count" {
  description = "number of Cloud Connectors to deploy.  Validation assumes max for /24 subnet but could be smaller or larger as long as subnet can accommodate"
  type    = number
  default = 2
   validation {
          condition     = var.cc_count >= 1 && var.cc_count <= 250
          error_message = "Input cc_count must be a whole number between 1 and 250."
        }
}

variable "http_probe_port" {
  description = "port for Cloud Connector cloud init to enable listener port for HTTP probe from LB"
  default = 0
  validation {
          condition     = (
            var.http_probe_port == 0 ||
            var.http_probe_port == 80 ||
          ( var.http_probe_port >= 1024 && var.http_probe_port <= 65535 )
        )
          error_message = "Input http_probe_port must be set to a single value of 80 or any number between 1024-65535."
      }
}
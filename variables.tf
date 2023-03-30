variable "name" {
  description = "Custom name for VNETs and instances"
  type        = string
}

variable "region" {
  description = "The Azure region to deploy this module in. Defaults to same region as transit gateway"
  type        = string
  default     = ""
}

variable "cidr" {
  description = "The CIDR range to be used for the VNET"
  type        = string
}

variable "account" {
  description = "The Azure account name, as known by the Aviatrix controller. Defaults to same account as transit gateway"
  type        = string
  default     = ""
}

variable "ha_gw" {
  description = "Set to false to deploy single sdwan gateway."
  type        = bool
  default     = true
}

variable "transit_gw" {
}

variable "transit_vnet" {
}

variable "sdwan_solution" {
  type = string
}

variable "template" {
  type    = string
  default = "fortigate_advanced"
}

variable "sdwan_as_number" {
  type = number
}

variable "instance_size" {
  description = "Azure Instance size for the SDWAN gateways"
  type        = string
  default     = "Standard_B2ms"
}

variable "username" {
  type    = string
  default = "azureadmin"
}

variable "password" {
  type    = string
  default = "Aviatrix#1234"
}

variable "pre_shared_key" {
  type = string
}

locals {
  region  = var.region != "" ? var.region : var.transit_gw.vpc_reg
  account = var.account != "" ? var.account : var.transit_gw.account_name
}

variable "size" {
  type    = string
  default = "Standard_F4"
}

// License Type to create FortiGate-VM
// Provide the license type for FortiGate-VM Instances, either byol or payg.
variable "license_type" {
  default = "payg"
}

variable "publisher" {
  type    = string
  default = "fortinet"
}

variable "fgtoffer" {
  type    = string
  default = "fortinet_fortigate-vm_v5"
}

// BYOL sku: fortinet_fg-vm
// PAYG sku: fortinet_fg-vm_payg_20190624
variable "fgtsku" {
  type = map(any)
  default = {
    byol = "fortinet_fg-vm"
    payg = "fortinet_fg-vm_payg_2022"
  }
}

variable "fgtversion" {
  type    = string
  default = "7.0.11"
}

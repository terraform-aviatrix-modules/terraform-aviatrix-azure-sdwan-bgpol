variable "name" {
  description = "Custom name for VNETs and instances"
  type        = string
  default     = ""
}

variable "region" {
  description = "The Azure region to deploy this module in"
  type        = string
}

variable "cidr" {
  description = "The CIDR range to be used for the VNET"
  type        = string
}

variable "account" {
  description = "The Azure account name, as known by the Aviatrix controller"
  type        = string
}

variable "ha_gw" {
  description = "Set to false to deploy single sdwan gateway."
  type        = bool
  default     = true
}

variable "transit_gateway" {
}

variable "transit_vnet" {
}

variable "sdwan_solution" {
  type = string
}

variable "instance_size" {
  description = "Azure Instance size for the Aviatrix gateways"
  type        = string
  default     = "Standard_B2ms"
}

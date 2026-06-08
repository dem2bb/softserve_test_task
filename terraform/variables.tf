variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
  default     = "eschool"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "denmarkeast"
}

variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "VM admin username"
  type        = string
  default     = "eschool"
}

variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 2
}
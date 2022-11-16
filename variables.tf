variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default     = "estudo-tf"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  type = string
  default = "East US"
}

variable "ssh_public_key" {
  description = "This variable defines the SSH Public Key for Linux/k8s Worker nodes"
  default = "C/Users/casam/.ssh/terraform.pub"
}
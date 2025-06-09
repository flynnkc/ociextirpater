variable "tenancy_ocid" {}

variable "user_ocid" {}

variable "private_key_path" {}

variable "fingerprint" {}

variable "private_key_password" {}

variable "compartment_id" {}

variable "region" {}

variable "label" {
  # Must be less than 15 characters
  default = "extirpater"
  type = string
}

variable "ssh_public_key" {
  type = string
  default = null
}

variable "extirpate_compartment" {
  type = string
}
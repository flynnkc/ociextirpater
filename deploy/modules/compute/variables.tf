variable "compartment_ocid" {}
variable "subnet_ocid" {}

variable "label" {
    type = string
}

variable "image_id" {
    type = string
    default = "ocid1.image.oc1.iad.aaaaaaaa6dj7xhprldzujybtmg4pqm2apaoyf4tk4jdkuweht3oh6lf6qpaq"
}
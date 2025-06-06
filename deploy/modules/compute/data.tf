data "oci_core_image" "this" {
    image_id = var.image_id
}

data "oci_identity_availability_domains" "this" {
    compartment_id = var.compartment_ocid
}

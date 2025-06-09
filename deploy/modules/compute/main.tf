resource "oci_core_instance" "this" {
  compartment_id = var.compartment_ocid
  display_name = "${var.label}-instance"
  preserve_boot_volume = false

  #Network
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[random_integer.ad.result].name
  create_vnic_details {
    subnet_id = var.subnet_ocid
    assign_public_ip = false
  }

  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }

  shape = "VM.Standard.E5.Flex"

  shape_config {
    memory_in_gbs = 8
    ocpus = 1
  }

  source_details {
    source_id = data.oci_core_image.this.image_id
    source_type = "image"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key == null ? "" : var.ssh_public_key
    user_data = base64encode(format("#!/bin/bash\n%s\n%s", "TOBEDELETED=${var.extirpate_compartment}", file("./scripts/bootstrap.sh")))
  }
}

resource "random_integer" "ad" {
  min = 1
  max = length(data.oci_identity_availability_domains.this.availability_domains)
}

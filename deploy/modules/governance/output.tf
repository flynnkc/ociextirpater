output "extirpater_tag" {
  value = "${oci_identity_tag_namespace.this.name}.${oci_identity_tag.this.name}"
}
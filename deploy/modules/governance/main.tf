resource "oci_identity_tag_namespace" "this" {
    # Can't be in extirpater cmp due to accidental self-deletion
    compartment_id = var.compartment_ocid
    description = "Tags for extirpater"
    name = "${var.label}-tag-namespace"
}

resource "oci_identity_tag" "this" {
    description = "Extirpater skip deletion"
    name = "Skip"
    tag_namespace_id = oci_identity_tag_namespace.this.id
}

resource "time_sleep" "wait_30_seconds" {
    depends_on = [ oci_identity_tag.this ]

    create_duration = "30s"
}
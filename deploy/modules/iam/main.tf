resource "oci_identity_dynamic_group" "this" {
    # Keeping in root to match default domain
    compartment_id = var.compartment_ocid
    description = "Dynamic Group for OCIExtirpater Instance"
    name = "${var.label}-dynamic-group"
    matching_rule = "All {instance.id = '${var.instance_ocid}'}"
}

resource "oci_identity_policy" "this" {
    depends_on = [ oci_identity_tag.this ]

    compartment_id = var.extirpate_compartment
    description = "Policies for OCIExtirpater"
    name = "${var.label}-policy"
    statements = [
        "Allow dynamic-group ${oci_identity_dynamic_group.this.name} to manage all-resources in compartment id ${var.extirpate_compartment}"
    ]

    defined_tags = {
        "${oci_identity_tag_namespace.this.name}.${oci_identity_tag.this.name}" = "True"
    }
}

resource "oci_identity_tag_namespace" "this" {
    # Can't be in extirpater cmp due to accidental self-deletion
    compartment_id = var.compartment_ocid
    description = "Tags for extirpater"
    name = "${var.label}-tag-namespace"
}

resource "oci_identity_tag" "this" {
    depends_on = [ oci_identity_tag_namespace.this ]
    
    description = "Extirpater skip deletion"
    name = "Skip"
    tag_namespace_id = oci_identity_tag_namespace.this.id
}
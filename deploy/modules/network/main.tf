resource "oci_core_vcn" "this" {
    compartment_id = var.compartment_ocid

    cidr_block = "172.16.0.0/26"
    display_name = "${var.label}-vcn"
    dns_label = "${var.label}"
}

resource "oci_core_subnet" "this" {
  compartment_id = var.compartment_ocid
  cidr_block = "172.16.0.0/28"
  vcn_id = oci_core_vcn.this.id
  display_name = "${var.label}-subnet"
  dns_label = "extirnet"

  route_table_id = oci_core_route_table.this.id
  prohibit_internet_ingress = true
  security_list_ids = [ oci_core_security_list.this.id ]
}

resource "oci_core_nat_gateway" "this" {
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_vcn.this.id
  display_name = "${var.label}-nat-gateway"
}

resource "oci_core_service_gateway" "this" {
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_vcn.this.id
  display_name = "${var.label}-service-gateway"
  #route_table_id = oci_core_route_table.this.id

  services {
    service_id = data.oci_core_services.this.services[0]["id"]
  }
}

resource "oci_core_route_table" "this" {
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_vcn.this.id
  display_name = "${var.label}-route-table"

  route_rules {
    destination = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.this.id
  }

  route_rules {
    destination = data.oci_core_services.this.services[0]["cidr_block"]
    destination_type = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.this.id
  }
}

resource "oci_core_security_list" "this" {
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_vcn.this.id
  display_name = "${var.label}-security-list"

  egress_security_rules {
    destination = data.oci_core_services.this.services[0]["cidr_block"]
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol = "all"
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol = "all"
  }
}
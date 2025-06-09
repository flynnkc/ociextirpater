module "network" {
  source         = "./modules/network"
  compartment_ocid = var.compartment_id
  label = var.label
}

module "compute" {
  source        = "./modules/compute"
  compartment_ocid = var.compartment_id
  label = var.label
  subnet_ocid = module.network.subnet_ocid
  ssh_public_key = var.ssh_public_key
  extirpate_compartment = var.extirpate_compartment
}

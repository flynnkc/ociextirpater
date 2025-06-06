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
}

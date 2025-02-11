import oci
from ociextirpater.OCIClient import OCIClient

class resourcemanager( OCIClient ):
    service_name = "Resource Manager"
    clientClass = oci.resource_manager.ResourceManagerClient

    objects = [
        {
            "name_singular"      : "Stack",
            "name_plural"        : "Stacks",

            "function_delete"    : "delete_stack",
        },

        {
            "name_singular"      : "Job",
            "name_plural"        : "Jobs",

            "function_delete"    : "cancel_job",
        },

        {
            "name_singular"      : "Private Endpoint",
            "name_plural"        : "Private Endpoints",

            "function_delete"    : "delete_private_endpoint",
        }
    ]

    def list_objects(self, o, region, this_compartment, **kwargs):
        if o["name_plural"] == "Stacks":
            return oci.pagination.list_call_get_all_results(
                getattr((self.clients[region]), "list_stacks"),
                **{"compartment_id":this_compartment}).data

        if o["name_plural"] == "Jobs":
            return oci.pagination.list_call_get_all_results(
                getattr((self.clients[region]), "list_jobs"),
                **{"compartment_id":this_compartment}).data

        if o["name_plural"] == "Private Endpoints":
            return oci.pagination.list_call_get_all_results(
                getattr((self.clients[region]), "list_private_endpoints"),
                **{"compartment_id":this_compartment}).data

        raise NotImplementedError

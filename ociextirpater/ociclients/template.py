import oci
from ociextirpater.OCIClient import OCIClient

class xxx( OCIClient ):
    service_name = "XXX"
    clientClass = oci.xxx.YYY

    objects = [
        # {
        #     "name_singular"      : "XXX",
        #     "name_plural"        : "XXXXs",

        #     "function_list"      : "list_xxx",
        #     "kwargs_list"        : {
        #                            },
        #     "formatter"          : lambda instance: "XXX instance with OCID {} / name '{}' is in state {}".format( instance.id, instance.name, instance.lifecycle_state ),
        #     "function_delete"    : "delete_xxx",
        # },
    ]

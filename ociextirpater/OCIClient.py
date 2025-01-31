import logging
import oci
import concurrent.futures


class OCIClient:
    config = None

    clientClass = None
    clients = {}
    compositeClientClass = None
    compositeClients = {}
    isRegional = True
    searches_are_recursive = False

    def shouldSkipTagged(self,found_object):
        logging.debug("Checking tag")

        taggedValue = None

        # TODO: I feel like these two can be combined But later
        if self.config.skiptagged.isDefined():
            logging.debug("Checking for defined tag")
            if self.config.skiptagged.tagName() in found_object.defined_tags[self.config.skiptagged.tagNamespace()].keys():
                logging.debug("Object has defined tag with name '{}' . '{}'".format(self.config.skiptagged.tagNamespace(), self.config.skiptagged.tagName()))
                taggedValue = found_object.defined_tags[self.config.skiptagged.tagNamespace()].get(self.config.skiptagged.tagName())
            else:
                logging.debug("Object is not tagged with defined tag '{}' . '{}'".format(self.config.skiptagged.tagNamespace(), self.config.skiptagged.tagName()))
                return False

        else:
            logging.debug("Checking for freeform tag")
            if hasattr( found_object, "freeform_tags") and None != found_object.freeform_tags and self.config.skiptagged.tagName() in found_object.freeform_tags.keys():

                logging.debug("Object has tag with name '{}'".format(self.config.skiptagged.tagName()))
                taggedValue = found_object.freeform_tags.get(self.config.skiptagged.tagName())
            else:
                logging.debug("Object is not tagged with freeform tag {}".format(self.config.skiptagged.tagName()))
                return False

        if not self.config.skiptagged.tagValue():
            logging.debug("Value of tag does not need to be checked")
            return True
        else:
            logging.debug("Comparing configured value '{}' to actual tag value '{}'".format( self.config.skiptagged.tagValue(), taggedValue))
            if self.config.skiptagged.tagValue() == taggedValue:
                logging.debug("Values match")
                return True
            else:
                logging.debug("Values do NOT match")
                return False

        logging.error("I should not have gotten here")
        pass

    def _init_regional_client(self,ociconfig,region):
        logging.debug("Initializing {} client for region {}".format(self.clientClass.__name__, region))
        rconfig = ociconfig
        logging.debug("Old region in this OCI config dict: {}".format(rconfig["region"]))
        rconfig["region"] = region
        logging.debug("New region in this OCI config dict: {}".format(rconfig["region"]))
        self.clients[region] = self.clientClass(rconfig, signer=self.config.signer)

        # if there's a Composite Client class specified then initialize that too
        if self.compositeClientClass:
            logging.debug("Now initializing {} composite client for region {}".format(self.compositeClientClass.__name__, region))
            self.compositeClients[region] = self.compositeClientClass( self.clients[region] )

    def __init__(self,config):
        logging.debug("OCIClient")
        self.config = config

        logging.info("Initializing clients...")

        # always initialize the client for the home region
        # this is the easy fix for issue 2 @ https://github.com/therealcmj/ociextirpater/issues/2
        logging.debug("Initializing OCI client in the home region for {}".format(self.clientClass.__name__))
        self._init_regional_client(config.ociconfig, config.home_region)

        # if the service IS a regional service then we need one client for each region
        # this was a good idea. But turns out that DNS as a service has both Global and Regional aspects
        if self.isRegional:
            logging.debug( "Initializing regional OCI clients for {}".format( self.clientClass.__name__))
            for region in self.config.regions:
                self._init_regional_client( config.ociconfig, region)

        logging.debug("{} {} clients initialized".format( len(self.clients), self.clientClass.__name__))

    def findAllInCompartment(self, region, o, this_compartment, **kwargs):
        # most of the find_ methods in the clients take the compartment as a param

        os = None

        # if "list_objects" in self.__getattribute__():
        # if self.__getattribute__("list_objects"):
        # TODO: oh man. I remember when I wrote this. I don't know what I was thinking, but this has got to get
        # refactored.
        if getattr(self, "list_objects", None):
            logging.debug("Trying 'list_objects' method in class {}".format( self.__class__.__name__))
            try:
                os = self.list_objects( o, region, this_compartment, **kwargs )
                return os
            except NotImplementedError:
                logging.debug("Not implemented for object '{}' - using '{}()' (this is OK)".format(  o["name_singular"], o["function_list"] ))

        # logging.debug("Calling {}".format( o["function_list"]))
        os = oci.pagination.list_call_get_all_results(getattr((self.clients[region]), o["function_list"]),
                                                      this_compartment,
                                                      **kwargs).data
        return os

    def predelete(self,object,region,found_object):
        pass

    # I'm not sure if I want to take an argument or not
    def findAndDeleteAllInCompartment(self):
        logging.info( "Finding and deleting all {}".format( self.service_name ) )
        # in cases where the searches aren't recursive we have to search all of the child compartments too
        compartments_to_search = self.config.all_compartments

        if self.searches_are_recursive:
            logging.debug("Searches for {} are recursive. No need to iterate all child compartments.".format( self.service_name ) )
            compartments_to_search = self.config.compartments

        for this_compartment in compartments_to_search:
            if this_compartment in self.config.compartments:
                logging.debug( "findAndDeleteAllInCompartment on main compartment {}".format(this_compartment))
            else:
                logging.debug( "findAndDeleteAllInCompartment on child compartment {}".format( this_compartment ))

            if 0 == self.config.threads:
                logging.info("Executing cleanup without threading. Consider increasing threads to improve performance.")
                for region in self.clients:
                    self.cleanupCompartmentInRegion(region, this_compartment)
            else:
                logging.info("Executing cleanup with {} threads".format( self.config.threads ))

                with concurrent.futures.ThreadPoolExecutor(max_workers=self.config.threads) as executor:
                    r = {executor.submit(self.cleanupCompartmentInRegion, region, this_compartment): region for region in self.clients}
                    for future in concurrent.futures.as_completed(r):
                        region = r[future]
                        logging.info("Region {} done for {}".format(region,self.service_name))

        logging.info("Cleanup of {} complete".format(self.service_name))

    def cleanupCompartmentInRegion(self, region, this_compartment):
        # self.objects is all of the "objects" the Client exposes
        for object in self.objects:
            logging.debug("Singular name: {}".format(object["name_singular"]))

            # self.clients is a dict from region name to the actual client for that region.
            logging.info(
                "Finding all {} in compartment {} in region {}".format(object["name_plural"], this_compartment, region))
            kwargs = {}

            if "kwargs_list" in object:
                kwargs = object["kwargs_list"]

            found_objects = []
            try:
                found_objects = self.findAllInCompartment(region, object, this_compartment, **kwargs)
            except Exception as e:
                logging.error("Unexpected exception caught calling {}".format(object["function_list"]))
                logging.error(e)

            logging.info("Found {} {}".format(len(found_objects), object["name_plural"]))

            # we need to filter out any that are in state DELETED
            for found_object in found_objects:
                if "formatter" in object:
                    try:
                        logging.info(object["formatter"](found_object))
                    except Exception as e:
                        logging.error(
                            "Exception using custom formatter to log one line description of object - please open an issue on GitHub")
                        logging.info(found_object)
                else:
                    try:
                        logging.info("{} with OCID {} / name '{}' is in state {}".format(object["name_singular"],
                                                                                         found_object.id,
                                                                                         found_object.display_name,
                                                                                         found_object.lifecycle_state))
                    except Exception as e:
                        logging.error("Exception logging one line description of object - please open an issue on GitHub")
                        logging.info(found_object)

                # Assume we're not supposed to delete
                delete = False
                if "check2delete" in object:
                    delete = object["check2delete"](found_object)
                    logging.debug("check2delete function returned {}".format(delete))
                # elif found_object.lifecycle_state == "DELETED" or found_object.lifecycle_state == "DELETING":
                elif (hasattr(found_object, "lifecycle_state") and
                      (found_object.lifecycle_state == "DELETED" or
                       found_object.lifecycle_state == "DELETE_SCHEDULED" or
                       found_object.lifecycle_state == "DELETING" or
                       found_object.lifecycle_state == "TERMINATED" or
                       found_object.lifecycle_state == "TERMINATING"
                      )
                ):
                    logging.debug("skipping")
                elif self.config.skiptagged and self.shouldSkipTagged(found_object):
                    logging.debug("skipping")
                else:
                    delete = True

                if not delete:
                    logging.debug("Not deleting")
                else:
                    logging.debug("Object will be deleted")
                    try:
                        # in some cases there are things we need to do before deleting.
                        # for example we may need to stop a compute or analytics instance before deleting it
                        # (this is a contrived example since computes don't need to be stopped before being deleted)
                        # in those cases the predelete() function should do that
                        self.predelete(object, region, found_object)
                    except Exception as e:
                        logging.error(
                            "Exception in pre-delete method. {} will not be deleted".format(object["name_singular"]))
                        logging.info(e)
                        delete = False

                    if delete:
                        logging.info("Deleting")
                        try:
                            kwargs = {}

                            if "kwargs_delete" in object:
                                kwargs = object["kwargs_delete"]

                            if "function_delete" in object:
                                f = getattr((self.clients[region]), object["function_delete"])
                                f(found_object.id, **kwargs)
                                logging.debug("Successful deletion")
                            elif "c_function_delete" in object:

                                f = getattr((self.compositeClients[region]), object["c_function_delete"])
                                f(found_object.id, **kwargs)
                                logging.debug("Successful deletion")
                            elif hasattr(self, "delete_object"):
                                self.delete_object(object, region, found_object)
                            else:
                                logging.debug("No way to delete object (this may be OK)")

                        except Exception as e:
                            logging.error("Failed to delete {} because {}".format(object["name_singular"], e))
                            logging.info("Object info: {}".format(found_object))
                            logging.debug(e)

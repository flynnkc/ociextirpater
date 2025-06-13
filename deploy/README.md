# Deploy OCIExtirpater Using OCI Resource Manager

## Steps

1. Click the "Deploy to Oracle Cloud" button and log into your tenancy.
2. Select compartment to deploy OCIExtirpater resources (Oracle Autonomous Linux Instance, etc.) in.
3. Select compartment to extirpate (Not the same compartment as resources to be deployed in!).
4. Optionally change the label to be applied to resources created by the stack.
5. Add one or more SSH keys for shell access to the Extirpater instance if needed.
6. Optionally select if you want to use a pre-existing VCN and Subnet.
7. Save and Apply the Stack.

## Variables

| Variable | Type | Required (ORM) | Required (Other Method) | Description |
| --- | --- | --- | --- | --- |
| tenancy_ocid | String |  | :white_check_mark: | OCID of the tenancy to deploy Extirpater |
| user_ocid | String |  | :white_check_mark: | OCID of user principal deploying Extirpater |
| private_key_path | String |  | :white_check_mark: | Path to private key associated with user principal |
| fingerprint | String |  | :white_check_mark: | Fingerprint of key associated with user principal |
| private_key_password | String |  |  | Password for private key associated with user principal |
| region | String |  | :white_check_mark: | OCI Region to deploy Extirpater in |
| compartment_id | String | :white_check_mark: | :white_check_mark: | Compartment to deploy Extirpater resources in |
| extirpate_compartment | String | :white_check_mark: | :white_check_mark: | Compartment to Extirpate (delete stuff) |
| label | String |  |  | Label to apply to resources deployed by Extirpater |
| ssh_public_key | String |  |  | SSH public key to add to Oracle Autonomous Linux instance running Extirpater |
| use_existing_network | Boolean |  |  | Flag to deploy solution to existing network |
| existing_vcn | String |  |  | OCID of OCI Virtual Cloud Network to deploy Extirpater resources in |
| existing_subnet | String |  |  | OCID of Subnet in VCN to deploy Extirpater resources in |

## Instance Info

An Oracle Autonomous Linux 9 instance is deployed in a (by default) private subnet. An SSH key can be added by entering the public key in the `ssh_public_key` variable to enable shell access.

Exitirpater will run once a day at 00:00 to delete all resources, except compartments, from the chosen `extirpate_compartment`. Logs for these runs will be kept in `/var/log/ociextirpater`.

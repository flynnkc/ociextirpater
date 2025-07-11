# README for ociextirpate

extirpate
: ex·tir·pate
: to completely erase or eradicate

## What it is and does

The OCI Extirpater is a command line tool that deletes everything within a compartment in every subscribed OCI region.

## How it does it

The tool uses the OCI SDK to

1. find every compartment underneath the specified root
2. find every object within that compartment
3. delete the object

The code for each object type is actually quite small (see ociclients/template.py).

In short that code declares:

* the class in the OCI SDK to be used
* (optionally) the "composite class" to be used
* the name (both singular and plural) for human-readable logging
* the method in the class used to list and delete the object
* (optionally) specific formatters to generate a "one-liner" for the object

A class may also override some of the stuff in OCIClient.py in cases where the client class works differently than
typical.

## Quick Start

**NOTE:** OCIExtirpate supports a number of command line options including allowing you to limit
the resource types and regions it explores and cleans.
Running ociextirpate.py without any command line options will show you command line help.

### Running from your laptop

1. Set up the OCI CLI following the [instructions in the public documentation](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)
1. copy the code to your machine
   * if you have registered your ssh key in GitHub:
     * run "git clone ssh://github.com/therealcmj/ociextirpater.git"
   * if you have **NOT** registered you ssh key in GitHub:
       * run `git clone https://github.com/therealcmj/ociextirpater.git`
1. cd into "ociextirpater"
1. run "./ociextirpate.py -c ocid1.compartment.oc1..XXXX"
   * replacing ocid1.compartment.oc1..XXXX with the compartment you want to clean

### Running in Cloud Shell

Since iterating over all child compartments, regions, and resources types is a slow process **and** Cloud Shell has
a relatively short timeout before disconnecting it is generally preferable to run extirpater from your laptop or
from a compute instance.

But if you **want** to run it from Cloud Shell that is supported:

1. open Cloud Shell
1. run `git clone https://github.com/therealcmj/ociextirpater.git`
   * You need to use https rather than ssh since you likely won't have an ssh key for your Cloud Shell registered in GitHub
1. cd into "ociextirpater"
1. run "./ociextirpate.py -c ocid1.compartment.oc1..XXXX -dt"
   * replacing ocid1.compartment.oc1..XXXX with the compartment you want to clean

### Automated Deployment

Use Terraform to deploy an Oracle Autonomous Linux VM running OCI Extirpater on a daily schedule. A compartment is designated for "cleanup" of resources that will be terminated by the script. Move resources to the "cleanup" compartment to be terminated on the next run, or move entire compartments and their contents to easily terminate all associated resources.

[Learn how to deploy here](./deploy/README.md)

## More info

### Blog post and more information
Check out my blog post at
<https://www.ateam-oracle.com/post/cleanup-an-oci-compartment>

### Available Arguments
```
usage: ociextirpate.py [-h] [-cf CONFIG_FILE] [-cp CONFIG_PROFILE] [-ip] [-dt] [-log LOG_FILE] [-force]
                       [-debug] [-skip_tagged SKIP_TAGGED] [-skip_delete_compartment] [-rg REGIONS]
                       [-c COMPARTMENT] [-o OBJECTS] [-t THREADS]

options:
  -h, --help            show this help message and exit
  -cf CONFIG_FILE       OCI Config file
  -cp CONFIG_PROFILE    Config Profile inside the config file
  -ip                   Use Instance Principals for Authentication
  -dt                   Use Delegation Token for Authentication
  -log LOG_FILE         output log file
  -force                force delete without confirmation
  -debug                Enable debug
  -skip_tagged SKIP_TAGGED
                        Skip resources tagged specific ways [namespace.]name[=value]
  -skip_delete_compartment
                        Skip Deleting the compartment at the end
  -rg REGIONS           Regions to delete comma separated (defaults to all subscribed regions)
  -c COMPARTMENT        top level compartment id to delete
  -o OBJECTS            Object catagories to work on. See docs for info
  -t THREADS            Number of threads
  ```

### A Note About Threading

... or "plz make it go fasterer"

TL;DR: generally you don't need to fiddle with the threads command line argument.


The command line option `-t` allows you to set the number of threads. You might think that more threads == more faster,
and it is true up to a point. But only up to a point.

Resources are often interdependent. For example, you can't delete a VCN until you delete the subnets. And you can't
delete any network stuff until you delete the VNICs associated with compute instances, private endpoints, etc in that
VCN. Working out all the interdependencies and cleaning them up in order is more complicated than you might think and
is more in the realm of something you'd want to do with Resource Manaager vs a Python script (no matter how good).

So I don't bother.

Instead, I take a resource grouping (like database, compute, network, etc.) and do the cleanup in every region in
parallel.

in pseudocode that is

* for each object grouping [e.g. compute]
  * start a thread for each region [e.g. us-ashburn-1, us-phoenix-1]
    * search and delete each object type [e.g. compute instance, compute image, capacity reservation]

This works fairly well in that it's reasonably quick while still staying below the speed that causes you to reach
API rate limits. But I am still experimenting with other models and this code and model is likely to change in the
future.

I default to setting the number of threads to the number of regions. So specifying a number larger than the number of
regions I'm extirpating won't make the process go any faster. 

There are 2 exceptions to this rule:
1. Within a region I **do** delete Objects in Buckets in parallel.
1. if you are using a debugger you will want to set threads to 0.
    * Wait, zero? What do you mean zero?
    * well, see if you set it to 1 I spin off a separate thread to do stuff
    * if you set it to 0 I do my work "in line" without spinning off a thread
    * and it is easier to understand what the heck is going on in a debugger with no extra threads
 



### Special cases

#### Compartments
Please note that deleting a compartment (1) can take up to 2 hours and (2) that you can only queue up to 5 deletions
at a time.

In order to help customers avoid problems this script treats compartments as a special case. When deleting compartments
the script:
* requests deletion of only 2 compartments per run
* marks a (theoretically) empty compartment with the freeform tag `ExtirpateAttempted` before attempting to delete it
* skips any compartments with the above tag

You can adjust this behavior by editing `ociextirpater/ociclients/compartments.py`.

This is generally not an issue for me and my team because we have this script running as a regularly scheduled job.
Even if we delete only 2 compartments each day eventually every empty compartment is removed. Or as they say "it'll
just work itself out naturally".


## Inspiration

This was inspired by Richard Garsthagen's work on [OCI Super Delete](https://github.com/AnykeyNL/OCI-SuperDelete). In
fact, I even stole (most of) the command line arguments from his script. Making this *almost* a drop in replacement.

I wanted to try my hand at something similar but that was less "code" and more "declarative". Mostly because I thought
it would be nice to be able to add new object types to be deleted by simply declaring them rather than needing to write
a bunch of code.

In the end I'm not sure my approach was better or worse (OCIClient.py is practically unreadable) but it was a good
learning experience!

## What's next

* adding more objects
* trying to use the [Search service](https://docs.oracle.com/en-us/iaas/Content/Search/home.htm) instead of iterating over every object type

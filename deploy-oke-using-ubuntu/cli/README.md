# Deploy Ubuntu Nodes on OKE with CLI

This is a complete example based on the How-To [Deploy Ubuntu OKE nodes using CLI](https://canonical-oracle.readthedocs-hosted.com/oracle-how-to/deploy-ubuntu-oke-nodes-using-cli/), demonstrating how to launch Ubuntu nodes on OKE using the `oci` CLI.

## Prerequisites

* Configured Oracle Cloud [Account](https://docs.oracle.com/en/cloud/paas/content-cloud/administer/create-and-activate-oracle-cloud-account1.html), [User](https://docs.oracle.com/en-us/iaas/Content/GSG/Tasks/addingusers.htm), [Compartment](https://docs.oracle.com/en-us/iaas/Content/Identity/compartments/To_create_a_compartment.htm), and [API Keys](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm?utm_source=chatgpt.com)
* `jq` installed
* `kubectl` installed
* Oracle's `oci` CLI installed
* [Creating a Dynamic Group and a Policy for Self-Managed Nodes](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengdynamicgrouppolicyforselfmanagednodes.htm#contengprereqsforselfmanagednodes-accessreqs) (optional, self-managed)

You can install the required tools on Ubuntu with the following:

```bash
sudo snap install kubectl --classic
sudo snap install jq
```

The `oci` CLI has [installation instructions on their repository](https://github.com/oracle/oci-cli).

## Project structure

This example consists of three parts:

1. **Creating and setting up the networking resources for the cluster**
2. **Creating the OKE cluster**
3. **Creating a managed node pool OR creating self-managed node instances**

The following files are provided:

* `env.sh` — contains important parameters for the resources that will be created, including tenancy and compartment information.
* `setup_networking.sh` — creates a VCN, internet, NAT, and service gateways, security lists, and subnets.
* `create_cluster.sh` — creates an OKE cluster without nodes. It relies on the network resources set up previously.
* `create_managed_nodes.sh` — creates a managed node pool in the previously created cluster.
* `create_self_managed_nodes.sh` — creates a single self-managed node instance which will join the previously created cluster.
* `create_security_lists.sh` — invoked by `setup_networking.sh` for creating security lists.

## Usage

**NOTE**: Running these scripts will create resources in your Oracle cloud tenancy. They have a logical dependency between them so the order in which they are run matters. They are also not idempotent because most resource names are not unique identifiers. Run with **caution**.

* Replace necessary information in the `env.sh` file (e.g. `COMPARTMENT_ID`). Some basic default values are provided for many parameters. However, they are not for use in production because of how wide/open they are.
* Read the content of each file before executing it.
* Run `./setup_networking.sh`. If there are any errors, the script will fail and you will need to correct them before proceeding.
* Run `create_cluster.sh` to create the OKE cluster with no nodes.
* Run `create_managed_nodes.sh` or `create_self_managed_nodes.sh` to create the respective type of nodes. Note that some of these scripts create resources that you wouldn't want to duplicate. Therefore, consider commenting out sections that you don't want to run again.

# Deploy Ubuntu Nodes on OKE with Terraform

The following is a complete example from the How-To [Deploy OKE nodes using Ubuntu images](https://canonical-oracle.readthedocs-hosted.com/oracle-how-to/deploy-oke-nodes-using-ubuntu-images/) on launching Ubuntu nodes on OKE using Terraform.

## Prerequisites

* Configured Oracle Cloud [Account](https://docs.oracle.com/en/cloud/paas/content-cloud/administer/create-and-activate-oracle-cloud-account1.html), [User](https://docs.oracle.com/en-us/iaas/Content/GSG/Tasks/addingusers.htm), [Compartment](https://docs.oracle.com/en-us/iaas/Content/Identity/compartments/To_create_a_compartment.htm), and [API Keys](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm?utm_source=chatgpt.com)
* `terraform` installed
* `yq` installed
* `kubectl` installed
* Oracle's `oci` CLI installed
* [Creating a Dynamic Group and a Policy for Self-Managed Nodes](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengdynamicgrouppolicyforselfmanagednodes.htm#contengprereqsforselfmanagednodes-accessreqs) (optional)

You can install the required tools on Ubuntu with the following:
```bash
sudo snap install kubectl --classic
sudo snap install terraform --classic
sudo snap install yq
```

The `oci` CLI has [installation instructions on their repository](https://github.com/oracle/oci-cli).

## Launching the Cluster

This repository contains all the required HCL to launch an OKE cluster with the option of either creating Managed or Self-Managed nodes using Ubuntu.

To start the process clone this repository, navigate to this directory and copy the example `.tfvars` file into the one we'll be using:
```bash
git clone https://github.com/canonical/oracle-doc-examples
cd oracle-doc-examples/deploy-oke-using-ubuntu/terraform
cp terraform.tfvars.example terraform.tfvars
```

It's important that the copied file be named `terraform.tfvars` as Terraform will automatically use files following this naming convention, otherwise you can pass the `-var-file=` flag instead.

Next, update the contents of the `terraform.tfvars` file with your values, most of which can be found in your `~/.oci/config` file. It's required to provide SSH keys as this will allow you to access the nodes for debugging purposes. Additionally, the `image_id` will be the OCID generated from registering your Ubuntu OKE image from the [Deploy OKE nodes using Ubuntu images](https://canonical-oracle.readthedocs-hosted.com/oracle-how-to/deploy-oke-nodes-using-ubuntu-images/#register-an-ubuntu-image) How-To. This repo will by default use `amd64` as it's architecture but you can use `-var=architecture=arm64` to use an ARM instance but the registered image must be an ARM image as well.

The following is an example of the contents of `terraform.tfvars`:
```
# Required
tenancy_ocid         = "ocid1.tenancy.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
user_ocid            = "ocid1.user.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
compartment_ocid     = "ocid1.compartment.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
fingerprint          = "xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx"
private_key_path     = "~/.oci/oci.pem"
region               = "us-phoenix-1"
kubernetes_version   = "v1.32.1"
image_id = "ocid1.image.oc1.phx.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
ssh_public_key_path  = "~/.ssh/id_rsa.pub"
ssh_private_key_path = "~/.ssh/id_rsa"

# Optional
public_nodes           = false
add_managed_nodes      = false
add_self_managed_nodes = false
```

Before continuing on launching the cluster and creating the nodes, be sure to follow [Creating a Dynamic Group and a Policy for Self-Managed Nodes](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengdynamicgrouppolicyforselfmanagednodes.htm#contengprereqsforselfmanagednodes-accessreqs) in the [Prerequisites](#Prerequisites) section if you wish to create Self-Managed nodes. This step is required to allow the standalone VMs to have permission to join the cluster.

Otherwise, you can initialize the Terraform project with:
```bash
terraform init
```

By default zero nodes will be created, so you must toggle which nodes you'd like to add. This can be done via `terraform.tfvars` file like so:
```
# Optional
public_nodes           = false
add_managed_nodes      = false
add_self_managed_nodes = false
```

Alternatively, the `.tfvars` can be overridden at launch time with the following `-var` flags:
```bash
terraform apply -var="add_managed_nodes=true" -var="add_self_managed_nodes=true"
```

It should be noted that you're able to create *both* node types for the cluster at once.

Once Terraform has reached it's desired state, the `kubeconfig` can be retrieved with the following:
> Warning! This will override your current `~/.kube/config` if one already exists.
```bash
mkdir -p ~/.kube/
terraform output -json cluster_kubeconfig | yq -p json | tee ~/.kube/config
```

Finally you can verify the state of the cluster with:
```bash
kubectl get nodes -o wide
```

Tearing down the networking, cluster and nodes is done with the following:
```bash
terraform destroy
```

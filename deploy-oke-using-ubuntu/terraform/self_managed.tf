# Self-managed instances are standalone VMs that connect
# to the cluster with specific cloud-init and compartment
# level permissions.
# 
# Learn more about the compartment level permissions at:
# https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengdynamicgrouppolicyforselfmanagednodes.htm#contengprereqsforselfmanagednodes-accessreqs
resource "oci_core_instance" "self_managed_nodes" {
  count = var.add_self_managed_nodes ? 3 : 0

  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  display_name        = "oke-self-managed-node-${count.index + 1}"
  shape               = local.instance_shape

  shape_config {
    ocpus         = 2
    memory_in_gbs = 16
  }

  source_details {
    source_type = "image"
    source_id   = var.image_id
  }

  create_vnic_details {
    subnet_id        = module.oke.worker_subnet_id
    assign_public_ip = var.public_nodes
    nsg_ids          = [module.oke.worker_nsg_id]
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data = base64encode(
      templatefile("./user-data/self-managed.yaml", {
        api_server_endpoint = module.oke.apiserver_private_host
        cluster_ca_cert     = module.oke.cluster_ca_cert
      })
    )
  }
  preserve_boot_volume = false
}

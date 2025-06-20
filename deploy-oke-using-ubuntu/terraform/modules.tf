# OKE module handles the creation and management of Networking, Cluster and Managed Nodes
module "oke" {
  source  = "oracle-terraform-modules/oke/oci"
  version = "5.2.4"

  # Connects the "oke" module to "oracle/oci" provider
  providers = {
    oci.home = oci.home
  }

  # Identity and access parameters
  tenancy_id           = var.tenancy_ocid
  compartment_id       = var.compartment_ocid
  region               = var.region
  home_region          = data.oci_identity_region_subscriptions.home_region_subscriptions.region_subscriptions[0].region_name
  api_fingerprint      = var.fingerprint
  api_private_key_path = var.private_key_path
  user_id              = var.user_ocid

  # General OCI parameters
  timezone = "Americas/Chicago"

  # SSH keys
  ssh_public_key_path  = var.ssh_public_key_path
  ssh_private_key_path = var.ssh_private_key_path

  # Networking
  vcn_name      = "oke-vcn"
  vcn_dns_label = "okevcn"
  subnets = {
    cp      = { newbits = 13, netnum = 2, dns_label = "cp", create = "always" }
    int_lb  = { newbits = 11, netnum = 16, dns_label = "ilb", create = "always" }
    pub_lb  = { newbits = 11, netnum = 17, dns_label = "plb", create = "always" }
    workers = { newbits = 2, netnum = 1, dns_label = "workers", create = "always" }
    pods    = { newbits = 2, netnum = 2, dns_label = "pods", create = "always" }
  }

  # Simplify our demo deployment disabling the creation of a bastion
  # and an operator server.
  create_operator = false
  create_bastion  = false

  # Tune to only create the minimum permissions
  create_iam_resources         = true
  create_iam_autoscaler_policy = "never"
  create_iam_operator_policy   = "never"
  create_iam_kms_policy        = "never"

  # Cluster
  cluster_name       = "oke-cluster"
  cluster_type       = "enhanced" # Required for self-managed nodes
  cni_type           = var.cni_type
  kubernetes_version = var.kubernetes_version
  pods_cidr          = "10.244.0.0/16"
  services_cidr      = "10.96.0.0/16"

  # Worker pool
  worker_pool_size  = 0
  worker_pool_mode  = "node-pool"
  worker_is_public  = var.public_nodes
  worker_image_id   = var.image_id
  worker_image_type = "custom"
  worker_image_os   = "Canonical Ubuntu"
  worker_shape      = { shape = local.instance_shape, ocpus = 2, memory = 32, boot_volume_size = 50 }

  # Remove default cloud-init provided to Oracle Linux images
  worker_disable_default_cloud_init = true

  # Add a node-pool if 'add_managed_nodes=true'
  worker_pools = var.add_managed_nodes ? {
    ubuntu-oke = {
      description = "OKE-managed Node Pool with custom image",
      create      = true,
      size        = 3,
      cloud_init = [
        {
          content      = base64encode(file("./user-data/managed.yaml")),
          content_type = "text/cloud-config",
        },
      ]
    },
  } : {}

  # Enable values for testing and debugging the cluster
  allow_worker_ssh_access           = true
  control_plane_allowed_cidrs       = ["0.0.0.0/0"]
  control_plane_is_public           = true
  assign_public_ip_to_control_plane = true

  # Enables output of cluster details
  output_detail = true
}

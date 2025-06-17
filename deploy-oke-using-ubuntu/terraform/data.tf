# Required to get the 'home_region'
data "oci_identity_region_subscriptions" "home_region_subscriptions" {
  tenancy_id = var.tenancy_ocid
}

# Get all of the availability domains for the tenancy
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Find an OCID for an Ubuntu OKE images
data "oci_core_images" "oke_images" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04 Minimal"
  shape                    = "VM.Standard.E4.Flex"
  state                    = "AVAILABLE"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

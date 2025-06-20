# Variables for the OKE cluster deployment

variable "tenancy_ocid" {
  description = "OCI Tenancy OCID"
  type        = string
}

variable "user_ocid" {
  description = "OCI User OCID"
  type        = string
}

variable "fingerprint" {
  description = "API Key Fingerprint"
  type        = string
}

variable "private_key_path" {
  description = "Path to the OCI API private key"
  type        = string
}

variable "region" {
  description = "OCI Region"
  type        = string
}

variable "compartment_ocid" {
  description = "OCI Compartment OCID"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key"
  type        = string
}

variable "kubernetes_version" {
  description = "Version used for the OKE control plane"
  type        = string
  default     = "v1.32.1"
}

variable "cni_type" {
  description = "Container networking type used within the OKE cluster (default 'flannel')"
  type        = string
  default     = "flannel"

  validation {
    condition     = contains(["flannel", "npn"], var.cni_type)
    error_message = "Invalid cni_type. Options include 'flannel' and 'npn'."
  }
}

variable "architecture" {
  description = "CPU Architecture to use for worker instances. Must match the provided 'image_id'. (default 'amd64')"
  type        = string
  default     = "amd64"

  validation {
    condition     = contains(["amd64", "arm64"], var.architecture)
    error_message = "Invalid architecture. Options include 'amd64' and 'arm64'."
  }
}

variable "add_managed_nodes" {
  description = "Adds managed nodes to the cluster when supplied (default 'false')"
  type        = bool
  default     = false
}

variable "add_self_managed_nodes" {
  description = "Adds self-managed nodes to the cluster when supplied (default 'false')"
  type        = bool
  default     = false
}

variable "public_nodes" {
  description = "Enable the worker nodes to be public (default 'false')"
  type        = bool
  default     = false
}

variable "image_id" {
  description = "OCID of the Ubuntu OKE image to be used"
  type        = string
}

#!/bin/bash

# The following values MUST be replaced
export COMPARTMENT_ID="<COMPARTMENT_ID>"
export REGION_NAME="<REGION_NAME>"
export IMAGE_OCID="<IMAGE_OCID>" # See https://canonical-oracle.readthedocs-hosted.com/oracle-how-to/deploy-oke-nodes-using-ubuntu-images/#register-an-ubuntu-image
export KUBE_CONFIG_PATH="<KUBE_CONFIG_PATH>"
export SSH_PUB_KEY_PATH="<SSH_PUB_KEY_PATH>"

COMPARTMENT_NAME=$(oci iam compartment get --compartment-id "$COMPARTMENT_ID" --query "data.name" --raw-output)
export COMPARTMENT_NAME
export VCN_NAME="oke-custom-vcn"

# Security list rules configuration
export SERVICE_GATEWAY_NAME="oke-service-gateway"
export NAT_GATEWAY_NAME="oke-nat-gateway"
export CIDR_BLOCK_VCN="10.0.0.0/16"
export CIDR_BLOCK_SUBNET_NODES="10.0.10.0/24"
export CIDR_BLOCK_SUBNET_CP="10.0.0.0/28"
export CIDR_BLOCK_SUBNET_SVCLB="10.0.20.0/24"
export IPPROTO_ALL="all"
export IPPROTO_ICMP="1"
export IPPROTO_TCP="6"
export ROUTE_TABLE_NAME="oke-public-route-table"
export NODES_SECLIST_NAME="oke-nodes-seclist"
export CP_SECLIST_NAME="oke-control-plane-seclist"
export SVCLB_SECLIST_NAME="oke-service-lb-seclist"

# Subnet configuration
export NODES_SUBNET_NAME="oke-nodes-subnet"
export CONTROL_PLANE_SUBNET_NAME="oke-control-plane-subnet"
export SERVICE_LOAD_BALANCER_NAME="oke-service-lb-subnet"

# Cluster configuration
export CLUSTER_NAME="oke-cluster"
export KUBE_VERSION="v1.32.1"
export CNI_TYPE="FLANNEL_OVERLAY"
export NODE_SHAPE="VM.Standard.E4.Flex" # Change depending on architecture of the chosen image
export NODE_CPUS="2"
export NODE_MEMORY="4"
export NUM_NODES="3"

# Domain and Policy configuration
export DOMAIN_NAME="oke-domain"
export DYNAMIC_GROUP_NAME="oke-domain-dynamic-group"


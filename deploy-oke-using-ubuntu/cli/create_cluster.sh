#!/bin/bash
#
# This script creates an OKE (Oracle Kubernetes Engine) enhanced cluster in Oracle Cloud.
# It:
#   - Retrieves required network resource OCIDs
#   - Creates the OKE cluster
#   - Generates a kubeconfig file for cluster access
# Usage: ./create_cluster.sh
#
set -euo pipefail

source env.sh

VCN_OCID=$(oci network vcn list --compartment-id "$COMPARTMENT_ID" \
    --display-name "$VCN_NAME" --query "data[0].id" --raw-output)
CP_SUBNET_OCID=$(oci network subnet list --compartment-id "$COMPARTMENT_ID" \
    --vcn-id "$VCN_OCID" --display-name "$CONTROL_PLANE_SUBNET_NAME" --query "data[0].id" --raw-output)
SVCLB_SUBNET_OCID=$(oci network subnet list --compartment-id "$COMPARTMENT_ID" \
    --vcn-id "$VCN_OCID" --display-name "oke-service-lb-subnet" --query "data[0].id" --raw-output)

# Create OKE enhanced cluster
CREATE_OUTPUT=$(oci ce cluster create \
    --compartment-id "$COMPARTMENT_ID" \
    --name "$CLUSTER_NAME" \
    --cluster-pod-network-options "[{\"cniType\": \"$CNI_TYPE\"}]" \
    --vcn-id "$VCN_OCID" \
    --endpoint-subnet-id "$CP_SUBNET_OCID" \
    --endpoint-public-ip-enabled true \
    --kubernetes-version "$KUBE_VERSION" \
    --service-lb-subnet-ids "[\"$SVCLB_SUBNET_OCID\"]" \
    --type "ENHANCED_CLUSTER" \
    --wait-for-state "SUCCEEDED")

CLUSTER_ID=$(echo "$CREATE_OUTPUT" | jq -r '.data.id')

# Create kubeconfig
oci ce cluster create-kubeconfig \
    --cluster-id "$CLUSTER_ID" \
    --file "$KUBE_CONFIG_PATH" \
    --kube-endpoint PUBLIC_ENDPOINT

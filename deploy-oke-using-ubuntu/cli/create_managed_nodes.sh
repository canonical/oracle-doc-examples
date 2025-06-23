#!/bin/bash
#
# This script creates a managed node pool for an OKE cluster in Oracle Cloud.
# It:
#   - Retrieves cluster and networking information
#   - Prepares user data for node bootstrapping
#   - Launches a managed node pool with the specified configuration
# Usage: ./create_managed_nodes.sh
#
set -euo pipefail

source env.sh

CLUSTER_ID=$(oci ce cluster list --compartment-id "$COMPARTMENT_ID" --name "$CLUSTER_NAME" \
    --output json | jq -r '.data[] | select(."lifecycle-state" == "ACTIVE") | .id')
VCN_OCID=$(oci network vcn list --compartment-id "$COMPARTMENT_ID" \
    --display-name "$VCN_NAME" --query "data[0].id" --raw-output)
    
# Create user data for managed node bootstrapping
USER_DATA=$(cat <<EOF
#cloud-config

runcmd:

  - oke bootstrap
EOF
)

AVAILABILITY_DOMAIN=$(oci iam availability-domain list --compartment-id "$COMPARTMENT_ID" \
    --query "data[0].name" --raw-output)
NODES_SUBNET_OCID=$(oci network subnet list --compartment-id "$COMPARTMENT_ID" \
    --vcn-id "$VCN_OCID" --display-name "$NODES_SUBNET_NAME" --query "data[0].id" --raw-output)

# Managed node pool creation
oci ce node-pool create \
    --compartment-id "$COMPARTMENT_ID" \
    --cluster-id "$CLUSTER_ID" \
    --name "default" \
    --kubernetes-version "$KUBE_VERSION" \
    --node-shape "$NODE_SHAPE" \
    --node-shape-config "{\"ocpus\": \"$NODE_CPUS\", \"memoryInGBs\": $NODE_MEMORY}" \
    --node-source-details '{
        "sourceType": "IMAGE",
        "imageId": "'"$IMAGE_OCID"'"
    }' \
    --node-metadata '{"user_data": "'"$(echo "$USER_DATA" | base64 -w0)"'"}' \
    --ssh-public-key "$(cat "$SSH_PUB_KEY_PATH")" \
    --size "$NUM_NODES" \
    --placement-configs '[{"availabilityDomain": "'"$AVAILABILITY_DOMAIN"'", "subnetId": "'"$NODES_SUBNET_OCID"'"}]' \
    --wait-for-state SUCCEEDED

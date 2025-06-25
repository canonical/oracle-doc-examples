#!/bin/bash
#
# This script creates a self-managed node for an OKE cluster in Oracle Cloud.
# It:
#   - Retrieves cluster and networking information
#   - Sets up required IAM domain, dynamic group, and policy
#   - Launches a compute instance configured to join the OKE cluster
# Usage: ./create_self_managed_nodes.sh
#
set -euo pipefail

source env.sh

# Setup Domain, Dynamic Group and Policy for self-managed nodes.
# This only needs to be done once. Comment out if running multiple times.
DOMAIN_OUTPUT=$(oci iam domain create \
    --compartment-id "$COMPARTMENT_ID" \
    --description "Domain for OKE cluster" \
    --display-name "$DOMAIN_NAME" \
    --license-type FREE \
    --home-region "$REGION_NAME" \
    --wait-for-state "SUCCEEDED")
echo "- Created Domain"
DOMAIN_ID=$(echo "$DOMAIN_OUTPUT" | jq -r '.data.resources[0].identifier')
DOMAIN_URL=$(oci iam domain get --domain-id "$DOMAIN_ID" --query "data.\"home-region-url\"" --raw-output | cut -d: -f1,2)

oci identity-domains dynamic-resource-group create \
    --endpoint "$DOMAIN_URL" \
    --compartment-ocid "$COMPARTMENT_ID" \
    --domain-ocid "$DOMAIN_ID" \
    --display-name "$DYNAMIC_GROUP_NAME" \
    --matching-rule "ALL {instance.compartment.id = '$COMPARTMENT_ID'}" \
    --schemas '["urn:ietf:params:scim:schemas:oracle:idcs:DynamicResourceGroup"]' \
    --description "Dynamic group for OKE cluster" > /dev/null
echo "- Created Dynamic Resource Group"

oci iam policy create \
  --compartment-id "$COMPARTMENT_ID" \
  --name "oke-dynamic-group-policy" \
  --description "Policy for OKE dynamic group" \
    --statements "[\"Allow dynamic-group '${DOMAIN_NAME}'/'${DYNAMIC_GROUP_NAME}' to {CLUSTER_JOIN} in compartment ${COMPARTMENT_NAME}\"]" \
  --wait-for-state "ACTIVE" > /dev/null
echo "- Created IAM Policy"


# Create user data for self-managed node bootstrapping

KUBE_CERT_DATA=$(grep "certificate-authority-data" "$KUBE_CONFIG_PATH" | awk '{print $2}')
CLUSTER_ID=$(oci ce cluster list --compartment-id "$COMPARTMENT_ID" --name "$CLUSTER_NAME" \
    --output json | jq -r '.data[] | select(."lifecycle-state" == "ACTIVE") | .id')
CONTROL_PLANE_IP=$(oci ce cluster get --cluster-id "$CLUSTER_ID" \
    --query "data.endpoints.\"private-endpoint\"" --raw-output | cut -d: -f1)
AVAILABILITY_DOMAIN=$(oci iam availability-domain list --compartment-id "$COMPARTMENT_ID" \
    --query "data[0].name" --raw-output)
VCN_OCID=$(oci network vcn list --compartment-id "$COMPARTMENT_ID" \
    --display-name "$VCN_NAME" --query "data[0].id" --raw-output)
NODES_SUBNET_OCID=$(oci network subnet list --compartment-id "$COMPARTMENT_ID" \
    --vcn-id "$VCN_OCID" --display-name "$NODES_SUBNET_NAME" --query "data[0].id" --raw-output)

USER_DATA=$(cat <<EOF
#cloud-config

runcmd:
  - oke bootstrap --ca $KUBE_CERT_DATA --apiserver-host $CONTROL_PLANE_IP

write_files:
  - path: /etc/oke/oke-apiserver
    permissions: '0644'
    content: $CONTROL_PLANE_IP
  - encoding: b64
    path: /etc/kubernetes/ca.crt
    permissions: '0644'
    content: $KUBE_CERT_DATA
EOF
)

METADATA='{
  "oke-native-pod-networking": false,
  "oke-max-pods": "5",
  "pod-subnets": "'"$NODES_SUBNET_OCID"'",
  "user_data": "'"$(echo "$USER_DATA" | base64 -w0)"'"
}'

# Self-managed node creation
oci compute instance launch \
    --compartment-id "$COMPARTMENT_ID" \
    --availability-domain "$AVAILABILITY_DOMAIN" \
    --shape "$NODE_SHAPE" \
    --shape-config "{\"ocpus\": \"$NODE_CPUS\", \"memoryInGBs\": $NODE_MEMORY}" \
    --display-name "oke-node-instance" \
    --image-id "$IMAGE_OCID" \
    --subnet-id "$NODES_SUBNET_OCID" \
    --metadata "$METADATA" \
    --ssh-authorized-keys-file "$SSH_PUB_KEY_PATH" \
    --wait-for-state "RUNNING" > /dev/null

echo "- Created self-managed node"

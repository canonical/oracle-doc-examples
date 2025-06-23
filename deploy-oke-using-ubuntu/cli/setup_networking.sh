#!/bin/bash
#
# This script sets up networking resources for an OKE cluster.
# It creates a VCN, internet gateway, NAT gateway, service gateway, security lists,
# and subnets for nodes, control plane, and service load balancer.
# Usage: ./setup_networking.sh
#
set -euo pipefail

source env.sh

# create a VCN
VCN_JSON=$(oci network vcn create \
    --compartment-id "$COMPARTMENT_ID" \
    --display-name "$VCN_NAME" \
    --cidr-block "$CIDR_BLOCK_VCN" \
    --wait-for-state "AVAILABLE")
VCN_OCID=$(echo "$VCN_JSON" | jq -r '.data.id')
echo "- VCN created: $VCN_OCID"

# Create internet gateway
IG_JSON=$(oci network internet-gateway create \
    --compartment-id "$COMPARTMENT_ID" \
    --vcn-id "$VCN_OCID" \
    --is-enabled true \
    --wait-for-state "AVAILABLE")
INTERNET_GATEWAY_OCID=$(echo "$IG_JSON" | jq -r '.data.id')
echo "- Internet Gateway created: $INTERNET_GATEWAY_OCID"

# Find the ALL service OCID for creating service gateway
ALL_SERVICE_OCID=$(oci network service list \
  --query "data[?starts_with(name, 'All')]|[0].id" --raw-output)
echo "- All Services OCID found: $ALL_SERVICE_OCID"

# Create service gateway
oci network service-gateway create \
    --compartment-id "$COMPARTMENT_ID" \
    --vcn-id "$VCN_OCID" \
    --display-name "$SERVICE_GATEWAY_NAME" \
    --services "[{\"serviceId\": \"$ALL_SERVICE_OCID\"}]" \
    --wait-for-state "AVAILABLE" > /dev/null
echo "- Service Gateway created"

# Create NAT gateway
oci network nat-gateway create \
    --compartment-id "$COMPARTMENT_ID" \
    --vcn-id "$VCN_OCID" \
    --display-name "$NAT_GATEWAY_NAME" \
    --wait-for-state "AVAILABLE" > /dev/null
echo "- NAT Gateway created"

# Create public route
RT_JSON=$(oci network route-table create \
    --compartment-id "$COMPARTMENT_ID" \
    --vcn-id "$VCN_OCID" \
    --display-name "$ROUTE_TABLE_NAME" \
    --route-rules '[{"destination": "0.0.0.0/0", "destinationType": "CIDR_BLOCK", "routeType": "STATIC", "networkEntityId": "'"$INTERNET_GATEWAY_OCID"'"}]' \
    --wait-for-state "AVAILABLE")
ROUTE_TABLE_OCID=$(echo "$RT_JSON" | jq -r '.data.id')
echo "- Route Table created: $ROUTE_TABLE_OCID"

# Create security lists
./create_security_lists.sh

# Create nodes subnet                
NODES_SECLIST_OCID=$(oci network security-list list --compartment-id "$COMPARTMENT_ID" \
    --vcn-id "$VCN_OCID" --display-name "$NODES_SECLIST_NAME" --query "data[0].id" --raw-output)

oci network subnet create \
    --compartment-id "$COMPARTMENT_ID" \
    --vcn-id "$VCN_OCID" \
    --display-name "$NODES_SUBNET_NAME" \
    --cidr-block "$CIDR_BLOCK_SUBNET_NODES" \
    --route-table-id "$ROUTE_TABLE_OCID" \
    --security-list-ids "[\"$NODES_SECLIST_OCID\"]" \
    --prohibit-internet-ingress false \
    --wait-for-state "AVAILABLE" > /dev/null
echo "- Nodes subnet created"

# Create control plane subnet
CP_SECLIST_OCID=$(oci network security-list list --compartment-id "$COMPARTMENT_ID" \
    --vcn-id "$VCN_OCID" --display-name "$CP_SECLIST_NAME" --query "data[0].id" --raw-output)
oci network subnet create \
    --compartment-id "$COMPARTMENT_ID" \
    --vcn-id "$VCN_OCID" \
    --display-name "$CONTROL_PLANE_SUBNET_NAME" \
    --cidr-block "$CIDR_BLOCK_SUBNET_CP" \
    --route-table-id "$ROUTE_TABLE_OCID" \
    --security-list-ids "[\"$CP_SECLIST_OCID\"]" \
    --wait-for-state "AVAILABLE" > /dev/null
echo "- Control plane subnet created"

# Create service load balancer subnet
SVCLB_SECLIST_OCID=$(oci network security-list list --compartment-id "$COMPARTMENT_ID" \
    --vcn-id "$VCN_OCID" --display-name "$SVCLB_SECLIST_NAME" --query "data[0].id" --raw-output)
oci network subnet create \
    --compartment-id "$COMPARTMENT_ID" \
    --vcn-id "$VCN_OCID" \
    --display-name "oke-service-lb-subnet" \
    --cidr-block "$CIDR_BLOCK_SUBNET_SVCLB" \
    --route-table-id "$ROUTE_TABLE_OCID" \
    --security-list-ids "[\"$SVCLB_SECLIST_OCID\"]" \
    --wait-for-state "AVAILABLE" > /dev/null
echo "- Service load balancer subnet created"

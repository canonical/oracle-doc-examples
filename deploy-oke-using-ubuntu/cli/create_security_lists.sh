#!/bin/bash
#
# This script creates security lists for OKE networking in Oracle Cloud.
# It:
#   - Retrieves the VCN OCID and the "All Services" CIDR block
#   - Creates security lists for nodes, control plane, and service load balancer
#   - Uses parameters from env.sh
#
# Usage: ./create_security_lists.sh
#
set -euo pipefail

source env.sh

VCN_OCID=$(oci network vcn list --compartment-id "$COMPARTMENT_ID" \
    --display-name "$VCN_NAME" --query "data[0].id" --raw-output)

# Find the ALL service CIDR_BLOCK
ALL_SERVICE_CIDR_BLOCK=$(oci network service list \
  --query "data[?starts_with(name, 'All')]|[0].\"cidr-block\"" --raw-output)

# Create nodes security list
oci network security-list create \
    --compartment-id "$COMPARTMENT_ID" \
    --vcn-id "$VCN_OCID" \
    --display-name "$NODES_SECLIST_NAME" \
    --egress-security-rules '[
        {
            "destination": "'"$CIDR_BLOCK_SUBNET_NODES"'",
            "protocol": "'"$IPPROTO_ALL"'",
        },
        {
            "destination": "'"$CIDR_BLOCK_SUBNET_CP"'",
            "protocol": "'"$IPPROTO_TCP"'",
            "tcpOptions": {
                "destinationPortRange": {
                    "min": 6443,
                    "max": 6443
                }
            }
        },
        {
            "destination": "'"$CIDR_BLOCK_SUBNET_CP"'",
            "protocol": "'"$IPPROTO_TCP"'",
            "tcpOptions": {
                "destinationPortRange": {
                    "min": 12250,
                    "max": 12250
                }
            }
        },
        {
            "destination": "'"$CIDR_BLOCK_SUBNET_CP"'",
            "protocol": "'"$IPPROTO_ICMP"'",
            "icmpOptions": {
                "type": 3,
                "code": 4
            }
        },
        {
            "destination": "'"$ALL_SERVICE_CIDR_BLOCK"'",
            "destinationType": "SERVICE_CIDR_BLOCK",
            "protocol": "'"$IPPROTO_TCP"'",
            "tcpOptions": {
                "destinationPortRange": {
                    "min": 443,
                    "max": 443
                }
            }
        },
        {
            "destination": "0.0.0.0/0",
            "protocol": "'"$IPPROTO_ICMP"'",
            "icmpOptions": {
                "type": 3,
                "code": 4
            }
        },
        {
            "destination": "0.0.0.0/0",
            "protocol": "'"$IPPROTO_ALL"'",
        }
    ]' \
    --ingress-security-rules '[
        {
            "source": "'"$CIDR_BLOCK_SUBNET_NODES"'",
            "protocol": "'"$IPPROTO_ALL"'",
        },
        {
            "source": "'"$CIDR_BLOCK_SUBNET_CP"'",
            "protocol": "'"$IPPROTO_ICMP"'",
            "icmpOptions": {
                "type": 3,
                "code": 4
            }
        },
        {
            "source": "'"$CIDR_BLOCK_SUBNET_CP"'",
            "protocol": "'"$IPPROTO_TCP"'",
        },
        {
            "source": "0.0.0.0/0",
            "protocol": "'"$IPPROTO_TCP"'",
            "tcpOptions": {
                "destinationPortRange": {
                    "min": 22,
                    "max": 22
                }
            }
        },
        {
            "source": "'"$CIDR_BLOCK_SUBNET_SVCLB"'",
            "protocol": "'"$IPPROTO_TCP"'",
            "tcpOptions": {
                "destinationPortRange": {
                    "min": 30234,
                    "max": 30234
                }
            }
        },
        {
            "source": "'"$CIDR_BLOCK_SUBNET_SVCLB"'",
            "protocol": "'"$IPPROTO_TCP"'",
            "tcpOptions": {
                "destinationPortRange": {
                    "min": 10256,
                    "max": 10256
                }
            }
        }
    ]' \
    --wait-for-state "AVAILABLE" > /dev/null
    
echo "- Nodes security list created"
 
# Create control plane security list
oci network security-list create \
  --compartment-id "$COMPARTMENT_ID" \
  --vcn-id "$VCN_OCID" \
  --display-name "$CP_SECLIST_NAME" \
  --egress-security-rules '[
    {
      "destination": "'"$ALL_SERVICE_CIDR_BLOCK"'",
      "destinationType": "SERVICE_CIDR_BLOCK",
      "protocol": "'"$IPPROTO_TCP"'",
      "tcpOptions": {
        "destinationPortRange": {
          "min": 443,
          "max": 443
        }
      }
    },
    {
      "destination": "'"$CIDR_BLOCK_SUBNET_NODES"'",
      "protocol": "'"$IPPROTO_TCP"'",
    },
    {
      "destination": "'"$CIDR_BLOCK_SUBNET_NODES"'",
      "protocol": "'"$IPPROTO_ICMP"'",
      "icmpOptions": {
        "type": 3,
        "code": 4
      }
    }
  ]' \
  --ingress-security-rules '[
    {
      "source": "0.0.0.0/0",
      "protocol": "'"$IPPROTO_TCP"'",
      "tcpOptions": {
        "destinationPortRange": {
          "min": 6443,
          "max": 6443
        }
      }
    },
    {
      "source": "'"$CIDR_BLOCK_SUBNET_NODES"'",
      "protocol": "'"$IPPROTO_TCP"'",
      "tcpOptions": {
        "destinationPortRange": {
          "min": 12250,
          "max": 12250
        }
      }
    },
    {
      "source": "'"$CIDR_BLOCK_SUBNET_NODES"'",
      "protocol": "'"$IPPROTO_ICMP"'",
      "icmpOptions": {
        "type": 3,
        "code": 4
      }
    }
  ]' \
  --wait-for-state "AVAILABLE" > /dev/null

echo "- Control Plane security list created"

# Create service load balancer security list
oci network security-list create \
    --compartment-id "$COMPARTMENT_ID" \
    --vcn-id "$VCN_OCID" \
    --display-name "$SVCLB_SECLIST_NAME" \
    --egress-security-rules '[
        {
            "destination": "'"$CIDR_BLOCK_SUBNET_NODES"'",
            "protocol": "'"$IPPROTO_TCP"'",
            "tcpOptions": {
                "destinationPortRange": {
                    "min": 30234,
                    "max": 30234
                }
            }
        },
        {
            "destination": "'"$CIDR_BLOCK_SUBNET_NODES"'",
            "protocol": "'"$IPPROTO_TCP"'",
            "tcpOptions": {
                "destinationPortRange": {
                    "min": 10256,
                    "max": 10256
                }
            }
        }
    ]' \
    --ingress-security-rules '[
        {
            "source": "'"0.0.0.0/0"'",
            "protocol": "'"$IPPROTO_TCP"'",
            "tcpOptions": {
                "destinationPortRange": {
                    "min": 80,
                    "max": 80
                }
            }
        }
    ]' \
    --wait-for-state "AVAILABLE" > /dev/null

echo "- Service LB security list created"

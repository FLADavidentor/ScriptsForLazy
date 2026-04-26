#!/usr/bin/env bash
set -euo pipefail

VPS_IP="167.86.74.77"
VPS_USER="root"
LIGHTHOUSE_IP="10.10.10.1"
NEBULA_PORT="4242"

read -rp "node name: " NODE
NODE="$(echo "$NODE" | tr -cd 'a-zA-Z0-9_-')"

if [ -z "$NODE" ]; then
  NODE="$(hostname | tr -cd 'a-zA-Z0-9_-')"
fi

if [ -f /etc/machine-id ]; then
  MACHINE_ID="$(cat /etc/machine-id)"
else
  MACHINE_ID="$(hostname)-$(uname -m)"
fi

TMP="/tmp/nebula-join-$NODE"
rm -rf "$TMP"
mkdir -p "$TMP"

# Call sub-scripts
bash nebula/scripts/install.sh
bash nebula/scripts/provision.sh "$VPS_USER" "$VPS_IP" "$NODE" "$MACHINE_ID" "$TMP"

REAL_NODE="$(cat "$TMP/real_node")"
NODE_IP="$(cat "$TMP/node_ip")"

bash nebula/scripts/service.sh "$REAL_NODE" "$LIGHTHOUSE_IP" "$VPS_IP" "$NEBULA_PORT"

echo "done."
echo "name: $REAL_NODE"
echo "ip: $NODE_IP"
echo "test ip: ping $LIGHTHOUSE_IP"

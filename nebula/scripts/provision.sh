#!/usr/bin/env bash
set -euo pipefail

VPS_USER="$1"
VPS_IP="$2"
NODE="$3"
MACHINE_ID="$4"
TMP="$5"

echo "[2] ask VPS for cave passport"
ssh -o StrictHostKeyChecking=accept-new "${VPS_USER}@${VPS_IP}" \
  "nebula-register '$NODE' '$MACHINE_ID'" | tar xz -C "$TMP"

CRT="$(find "$TMP" -maxdepth 1 -name '*.crt' ! -name 'ca.crt' | head -n1)"
KEY="$(find "$TMP" -maxdepth 1 -name '*.key' | head -n1)"
IPFILE="$(find "$TMP" -maxdepth 1 -name '*.ip' | head -n1)"

REAL_NODE="$(basename "$CRT" .crt)"
NODE_IP="$(cat "$IPFILE")"

echo "[3] install files"
sudo mkdir -p /etc/nebula
sudo cp "$TMP/ca.crt" /etc/nebula/
sudo cp "$CRT" "/etc/nebula/${REAL_NODE}.crt"
sudo cp "$KEY" "/etc/nebula/${REAL_NODE}.key"

sudo chown root:root /etc/nebula/*
sudo chmod 644 /etc/nebula/ca.crt "/etc/nebula/${REAL_NODE}.crt"
sudo chmod 600 "/etc/nebula/${REAL_NODE}.key"

echo "$REAL_NODE" > "$TMP/real_node"
echo "$NODE_IP" > "$TMP/node_ip"

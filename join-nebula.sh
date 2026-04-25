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

echo "[0] install nebula"
cd /tmp
curl -fL https://github.com/slackhq/nebula/releases/latest/download/nebula-linux-amd64.tar.gz -o /tmp/nebula.tar.gz
tar xzf /tmp/nebula.tar.gz -C /tmp
sudo install nebula nebula-cert /usr/local/bin/

echo "[1] clean old nebula"
sudo systemctl stop nebula 2>/dev/null || true
sudo systemctl disable nebula 2>/dev/null || true
sudo rm -f /etc/systemd/system/nebula.service
sudo systemctl daemon-reload 2>/dev/null || true
sudo rm -rf /etc/nebula
sudo ip link delete nebula1 2>/dev/null || true



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

echo "[4] write nebula config"
sudo tee /etc/nebula/config.yml >/dev/null <<EOF
pki:
  ca: /etc/nebula/ca.crt
  cert: /etc/nebula/${REAL_NODE}.crt
  key: /etc/nebula/${REAL_NODE}.key

static_host_map:
  "${LIGHTHOUSE_IP}": ["${VPS_IP}:${NEBULA_PORT}"]

lighthouse:
  am_lighthouse: false
  interval: 60
  hosts:
    - "${LIGHTHOUSE_IP}"

listen:
  host: 0.0.0.0
  port: ${NEBULA_PORT}

punchy:
  punch: true
  respond: true

tun:
  dev: nebula1
  mtu: 1300

firewall:
  outbound:
    - port: any
      proto: any
      host: any
  inbound:
    - port: any
      proto: icmp
      host: any
    - port: 22
      proto: tcp
      groups:
        - lighthouse
        - nodes
EOF

echo "[5] start forever"
if command -v systemctl >/dev/null && [ "$(ps -p 1 -o comm=)" = "systemd" ]; then
  sudo tee /etc/systemd/system/nebula.service >/dev/null <<EOF
[Unit]
Description=Nebula mesh
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/nebula -config /etc/nebula/config.yml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable --now nebula

  echo "[6] bind .nebula DNS to nebula1"
  for i in {1..10}; do
    if ip link show nebula1 >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done

fi

echo "done."
echo "name: $REAL_NODE"
echo "ip: $NODE_IP"
echo "test ip: ping $LIGHTHOUSE_IP"
echo "test dns: ping ${REAL_NODE}.nebula"

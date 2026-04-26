#!/usr/bin/env bash
set -euo pipefail

REAL_NODE="$1"
LIGHTHOUSE_IP="$2"
VPS_IP="$3"
NEBULA_PORT="$4"

# Load preferences
SSH_ENABLED=true
EXTRA_PORTS=""
OPEN_ALL_PORTS=false
if [ -f nebula/config.env ]; then
  source nebula/config.env
fi

# Build firewall rules
FW_RULES=""
if [ "$OPEN_ALL_PORTS" = "true" ]; then
  FW_RULES="    - port: any
      proto: any
      host: any
"
else
  if [ "$SSH_ENABLED" = "true" ]; then
    FW_RULES+="    - port: 22
      proto: tcp
      groups:
        - lighthouse
        - nodes
"
  fi

  if [ -n "$EXTRA_PORTS" ]; then
    for p in ${EXTRA_PORTS//,/ }; do
      FW_RULES+="    - port: $p
      proto: any
      host: any
"
    done
  fi
fi

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
${FW_RULES}
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
fi

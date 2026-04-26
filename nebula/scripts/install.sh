#!/usr/bin/env bash
set -euo pipefail

echo "[0] install nebula"
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  NB_ARCH="amd64" ;;
  aarch64) NB_ARCH="arm64" ;;
  armv7l)  NB_ARCH="arm"   ;;
  *) echo "Unsupported arch: $ARCH"; exit 1 ;;
esac

cd /tmp
curl -fL "https://github.com/slackhq/nebula/releases/latest/download/nebula-linux-${NB_ARCH}.tar.gz" -o /tmp/nebula.tar.gz
tar xzf /tmp/nebula.tar.gz -C /tmp
sudo install nebula nebula-cert /usr/local/bin/

echo "[1] clean old nebula"
sudo systemctl stop nebula 2>/dev/null || true
sudo systemctl disable nebula 2>/dev/null || true
sudo rm -f /etc/systemd/system/nebula.service
sudo systemctl daemon-reload 2>/dev/null || true
sudo rm -rf /etc/nebula
sudo ip link delete nebula1 2>/dev/null || true

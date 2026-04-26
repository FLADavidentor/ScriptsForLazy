#!/usr/bin/env bash
set -e

CONFIG="nebula/config.env"
touch "$CONFIG"
# Set defaults if empty
grep -q "SSH_ENABLED" "$CONFIG" || echo "SSH_ENABLED=true" >> "$CONFIG"
grep -q "EXTRA_PORTS" "$CONFIG" || echo "EXTRA_PORTS=\"\"" >> "$CONFIG"
grep -q "OPEN_ALL_PORTS" "$CONFIG" || echo "OPEN_ALL_PORTS=false" >> "$CONFIG"

source "$CONFIG"

echo "--- Nebula Configuration ---"
read -rp "Open ALL ports (any/any)? [y/n] (current: ${OPEN_ALL_PORTS}): " ALL_IN
if [ "$ALL_IN" = "y" ]; then OPEN_ALL_PORTS=true; fi
if [ "$ALL_IN" = "n" ]; then OPEN_ALL_PORTS=false; fi

if [ "$OPEN_ALL_PORTS" = "false" ]; then
  read -rp "Enable SSH (22)? [y/n] (current: ${SSH_ENABLED}): " SSH_IN
  if [ "$SSH_IN" = "y" ]; then SSH_ENABLED=true; fi
  if [ "$SSH_IN" = "n" ]; then SSH_ENABLED=false; fi

  read -rp "Extra ports (comma separated)? (current: ${EXTRA_PORTS}): " PORTS_IN
  if [ -n "$PORTS_IN" ]; then EXTRA_PORTS="$PORTS_IN"; fi
fi

cat > "$CONFIG" <<EOF
SSH_ENABLED=$SSH_ENABLED
EXTRA_PORTS="$EXTRA_PORTS"
OPEN_ALL_PORTS=$OPEN_ALL_PORTS
EOF

echo "Saved to $CONFIG"

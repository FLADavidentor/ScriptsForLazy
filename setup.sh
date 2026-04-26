#!/usr/bin/env bash
set -e

echo "--- setupscripties ---"
echo "1) Join Nebula Mesh"
echo "2) Configure Nebula Node"
echo "q) Quit"
read -rp "Select option: " CHOICE

case "$CHOICE" in
  1)
    bash nebula/join.sh
    ;;
  2)
    bash nebula/scripts/configure.sh
    ;;
  q)
    exit 0
    ;;
  *)
    echo "Invalid option"
    exit 1
    ;;
esac

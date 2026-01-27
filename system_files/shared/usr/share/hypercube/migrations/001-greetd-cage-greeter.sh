#!/bin/bash
# Migration: Update greetd to use cage + ghostty for greeter

set -euo pipefail

CONFIG="/etc/greetd/config.toml"

# Skip if file doesn't exist
[[ -f "$CONFIG" ]] || exit 0

# Skip if already using cage greeter
grep -q 'cage -s -- ghostty-kiosk hypercube-greeter' "$CONFIG" && exit 0

echo "Updating greetd default_session to use cage + ghostty-kiosk..."

# Only update the default_session command line
sed -i '/^\[default_session\]/,/^\[/ s|^command = .*|command = "cage -s -- ghostty-kiosk hypercube-greeter"|' "$CONFIG"

echo "greetd config updated"

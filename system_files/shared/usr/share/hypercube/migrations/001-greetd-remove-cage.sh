#!/bin/bash
# Migration: Remove cage references from greetd config

set -euo pipefail

CONFIG="/etc/greetd/config.toml"

# Skip if file doesn't exist
[[ -f "$CONFIG" ]] || exit 0

# Skip if already migrated (no cage reference)
grep -q "cage" "$CONFIG" || exit 0

echo "Updating greetd config to remove cage..."

cat > "$CONFIG" << 'EOF'
[terminal]
vt = 1

[default_session]
command = "hypercube-greeter"
user = "greeter"

[initial_session]
command = "hypercube-onboard --config /usr/share/hypercube/config/hypercube-onboard/onboard.toml"
user = "root"
EOF

echo "greetd config updated"

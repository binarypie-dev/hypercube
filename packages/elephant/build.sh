#!/bin/bash

set -ouex pipefail

# Install build dependencies for Elephant (Go-based)
dnf5 -y install git golang protobuf-compiler

# Clone Elephant repository
ELEPHANT_VERSION="v2.17.0"
git clone --depth 1 --branch ${ELEPHANT_VERSION} https://github.com/abenz1267/elephant.git /tmp/elephant

cd /tmp/elephant

# Set Go environment variables for build
export GOPATH=/tmp/go
export GOCACHE=/tmp/go-cache
export GOTOOLCHAIN=auto
export GOSUMDB=sum.golang.org

# Build Elephant
cd cmd/elephant
go build -o elephant elephant.go

# Install binary
install -Dm755 elephant /usr/bin/elephant

# Create systemd user service directory
mkdir -p /usr/lib/systemd/user

# Create systemd service file
cat > /usr/lib/systemd/user/elephant.service << 'EOF'
[Unit]
Description=Elephant Data Provider Service
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/elephant
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

# Clean up
cd /
rm -rf /tmp/elephant

# Remove build dependencies to keep layer small
dnf5 -y remove golang protobuf-compiler
dnf5 -y clean all


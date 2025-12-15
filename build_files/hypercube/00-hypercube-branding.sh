#!/bin/bash
# Hypercube OS Branding Script
# This script modifies os-release and creates branding files for Hypercube

set -ouex pipefail

# Variables (can be overridden via build args)
IMAGE_NAME="${IMAGE_NAME:-hypercube}"
IMAGE_VENDOR="${IMAGE_VENDOR:-binarypie-dev}"
IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
FEDORA_VERSION="${FEDORA_VERSION:-$(rpm -E %fedora)}"
BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-bluefin-dx}"

# Create image-info.json
mkdir -p /usr/share/hypercube
cat > /usr/share/hypercube/image-info.json << EOF
{
  "image-name": "${IMAGE_NAME}",
  "image-flavor": "${IMAGE_FLAVOR}",
  "image-vendor": "${IMAGE_VENDOR}",
  "image-ref": "ostree-image-signed:docker://ghcr.io/${IMAGE_VENDOR}/${IMAGE_NAME}",
  "image-tag": "${IMAGE_TAG:-latest}",
  "base-image-name": "${BASE_IMAGE_NAME}",
  "fedora-version": "${FEDORA_VERSION}"
}
EOF

# Modify /usr/lib/os-release for Hypercube branding
# Keep Bluefin as ID_LIKE since we inherit from it
if [ -f /usr/lib/os-release ]; then
    # Set NAME to Hypercube
    sed -i "s/^NAME=.*/NAME=\"Hypercube\"/" /usr/lib/os-release

    # Update PRETTY_NAME
    sed -i "s/^PRETTY_NAME=.*/PRETTY_NAME=\"Hypercube ${FEDORA_VERSION} (Fedora-based)\"/" /usr/lib/os-release

    # Set ID to hypercube, keep fedora and bluefin as ID_LIKE
    sed -i "s/^ID=.*/ID=hypercube/" /usr/lib/os-release

    # Update ID_LIKE to include both fedora and bluefin
    if grep -q "^ID_LIKE=" /usr/lib/os-release; then
        sed -i "s/^ID_LIKE=.*/ID_LIKE=\"bluefin fedora\"/" /usr/lib/os-release
    else
        echo 'ID_LIKE="bluefin fedora"' >> /usr/lib/os-release
    fi

    # Set VARIANT_ID
    if grep -q "^VARIANT_ID=" /usr/lib/os-release; then
        sed -i "s/^VARIANT_ID=.*/VARIANT_ID=${IMAGE_NAME}/" /usr/lib/os-release
    else
        echo "VARIANT_ID=${IMAGE_NAME}" >> /usr/lib/os-release
    fi

    # Update URLs to point to Hypercube project
    sed -i "s|^HOME_URL=.*|HOME_URL=\"https://github.com/${IMAGE_VENDOR}/${IMAGE_NAME}\"|" /usr/lib/os-release
    sed -i "s|^DOCUMENTATION_URL=.*|DOCUMENTATION_URL=\"https://github.com/${IMAGE_VENDOR}/${IMAGE_NAME}#readme\"|" /usr/lib/os-release
    sed -i "s|^SUPPORT_URL=.*|SUPPORT_URL=\"https://github.com/${IMAGE_VENDOR}/${IMAGE_NAME}/issues\"|" /usr/lib/os-release
    sed -i "s|^BUG_REPORT_URL=.*|BUG_REPORT_URL=\"https://github.com/${IMAGE_VENDOR}/${IMAGE_NAME}/issues\"|" /usr/lib/os-release

    # Update CPE_NAME
    sed -i "s|^CPE_NAME=.*|CPE_NAME=\"cpe:/o:${IMAGE_VENDOR}:${IMAGE_NAME}:${FEDORA_VERSION}\"|" /usr/lib/os-release

    # Set DEFAULT_HOSTNAME
    if grep -q "^DEFAULT_HOSTNAME=" /usr/lib/os-release; then
        sed -i "s/^DEFAULT_HOSTNAME=.*/DEFAULT_HOSTNAME=\"hypercube\"/" /usr/lib/os-release
    else
        echo "DEFAULT_HOSTNAME=\"hypercube\"" >> /usr/lib/os-release
    fi

    # Add IMAGE_ID and IMAGE_VERSION (systemd 249+ fields)
    if grep -q "^IMAGE_ID=" /usr/lib/os-release; then
        sed -i "s/^IMAGE_ID=.*/IMAGE_ID=${IMAGE_NAME}/" /usr/lib/os-release
    else
        echo "IMAGE_ID=${IMAGE_NAME}" >> /usr/lib/os-release
    fi

    if grep -q "^IMAGE_VERSION=" /usr/lib/os-release; then
        sed -i "s/^IMAGE_VERSION=.*/IMAGE_VERSION=${FEDORA_VERSION}/" /usr/lib/os-release
    else
        echo "IMAGE_VERSION=${FEDORA_VERSION}" >> /usr/lib/os-release
    fi

    # Remove Red Hat specific fields if present
    sed -i '/^REDHAT_BUGZILLA_PRODUCT=/d' /usr/lib/os-release
    sed -i '/^REDHAT_BUGZILLA_PRODUCT_VERSION=/d' /usr/lib/os-release
    sed -i '/^REDHAT_SUPPORT_PRODUCT=/d' /usr/lib/os-release
    sed -i '/^REDHAT_SUPPORT_PRODUCT_VERSION=/d' /usr/lib/os-release
fi

# Ensure /etc/os-release is a symlink to /usr/lib/os-release
if [ ! -L /etc/os-release ]; then
    rm -f /etc/os-release
    ln -sf ../usr/lib/os-release /etc/os-release
fi

echo "Hypercube branding applied successfully"

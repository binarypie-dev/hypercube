#!/bin/bash
# Hypercube image signature verification
# CI signs every pushed image with cosign (see .github/workflows/build.yml).
# This script makes installed systems actually check that signature: it ships
# the public key, tells containers/image to fetch sigstore signatures from
# GHCR, and adds a policy.json rule that requires them for our registry path.
# Without this, "ostree-image-signed" / "bootc switch --enforce-container-sigpolicy"
# have nothing to verify against. Same approach as ublue-os's own images.

set -ouex pipefail

IMAGE_VENDOR="${IMAGE_VENDOR:-binarypie-dev}"
REGISTRY_PATH="ghcr.io/${IMAGE_VENDOR,,}"
KEY_PATH="/etc/pki/containers/hypercube.pub"
POLICY="/etc/containers/policy.json"

### Public key (same key as cosign.pub in the repo root)
install -Dm644 /ctx/cosign.pub "${KEY_PATH}"

### Fetch sigstore signatures stored as OCI attachments on GHCR
install -d /etc/containers/registries.d
cat >/etc/containers/registries.d/hypercube.yaml <<EOF
docker:
  ${REGISTRY_PATH}:
    use-sigstore-attachments: true
EOF

### Require a valid signature for images from our registry path
# base-main ships policy.json with ublue-os's own rules; add ours alongside them.
if [[ ! -f "${POLICY}" ]]; then
    echo "ERROR: ${POLICY} not found in base image"
    exit 1
fi
tmp="$(mktemp)"
jq --arg repo "${REGISTRY_PATH}" --arg key "${KEY_PATH}" '
  .transports.docker[$repo] = [{
    "type": "sigstoreSigned",
    "keyPath": $key,
    "signedIdentity": {"type": "matchRepository"}
  }]' "${POLICY}" >"${tmp}"
install -m644 "${tmp}" "${POLICY}"
rm -f "${tmp}"

echo "Signature verification configured for ${REGISTRY_PATH}"

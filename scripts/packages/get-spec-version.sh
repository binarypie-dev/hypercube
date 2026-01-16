#!/bin/bash
# Get version from a package spec file

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="$(cd "$SCRIPT_DIR/../../packages" && pwd)"

usage() {
    echo "Usage: $0 <package-name>"
    echo ""
    echo "Get the version from a package's spec file."
    echo ""
    echo "Examples:"
    echo "  $0 starship"
    echo "  $0 hyprland"
    exit 1
}

if [[ $# -ne 1 ]]; then
    usage
fi

PACKAGE=$1
SPEC_FILE="$PACKAGES_DIR/$PACKAGE/$PACKAGE.spec"

if [[ ! -f "$SPEC_FILE" ]]; then
    echo "ERROR: Spec file not found: $SPEC_FILE" >&2
    exit 1
fi

VERSION=$(grep "^Version:" "$SPEC_FILE" | awk '{print $2}')
RELEASE=$(grep "^Release:" "$SPEC_FILE" | awk '{print $2}' | sed 's/%{?dist}//')

if [[ -z "$VERSION" ]]; then
    echo "ERROR: Could not parse version from $SPEC_FILE" >&2
    exit 1
fi

echo "${VERSION}-${RELEASE}"

#!/bin/bash
# Get upstream version for a package from GitHub

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

usage() {
    echo "Usage: $0 <package-name>"
    echo ""
    echo "Get the latest upstream version for a package from GitHub."
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

# Check if package exists in config
if [[ -z "${PACKAGE_REPOS[$PACKAGE]:-}" ]]; then
    echo "ERROR: Unknown package: $PACKAGE" >&2
    echo "Available packages: ${!PACKAGE_REPOS[@]}" >&2
    exit 1
fi

REPO="${PACKAGE_REPOS[$PACKAGE]}"
VERSION_SOURCE="${VERSION_SOURCES[$PACKAGE]:-release}"

# Get upstream version from GitHub
# Try gh first (if authenticated), fall back to curl
if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    # Use gh CLI (faster and more reliable if authenticated)
    if [[ "$VERSION_SOURCE" == "tag" ]]; then
        UPSTREAM=$(gh api "repos/$REPO/tags" --jq '.[0].name' 2>/dev/null || echo "")
    else
        UPSTREAM=$(gh api "repos/$REPO/releases/latest" --jq '.tag_name' 2>/dev/null || echo "")
    fi
else
    # Fall back to curl (works without authentication but has rate limits)
    if [[ "$VERSION_SOURCE" == "tag" ]]; then
        UPSTREAM=$(curl -sf "https://api.github.com/repos/$REPO/tags" 2>/dev/null | jq -r '.[0].name' 2>/dev/null || echo "")
    else
        UPSTREAM=$(curl -sf "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null | jq -r '.tag_name' 2>/dev/null || echo "")
    fi
fi

# Validate response
if [[ -z "$UPSTREAM" ]] || echo "$UPSTREAM" | grep -q "Not Found\|message"; then
    echo "ERROR: Could not determine upstream version for $PACKAGE from $REPO" >&2
    exit 1
fi

# Strip 'v' prefix if present
UPSTREAM="${UPSTREAM#v}"

echo "$UPSTREAM"

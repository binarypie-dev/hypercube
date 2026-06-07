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

# Prefer `rpmspec` for proper macro expansion (e.g. Version: %{major_version}.0
# in Fedora-style specs). Fall back to a header-only grep for environments
# without rpm tooling (some CI runners).
if command -v rpmspec &>/dev/null; then
    NVR=$(rpmspec -q --srpm --queryformat='%{VERSION}-%{RELEASE}\n' "$SPEC_FILE" 2>/dev/null)
    VERSION="${NVR%-*}"
    # Strip the dist tag (.fcXX) from RELEASE since callers don't want it.
    RELEASE=$(echo "${NVR##*-}" | sed -E 's/\.fc[0-9]+$//')
else
    # Only look at the spec header (before %prep) so we don't pick up stray
    # `Version:` lines inside pkg-config heredocs or other generated content.
    HEADER=$(sed -n '1,/^%prep/p' "$SPEC_FILE")
    VERSION=$(echo "$HEADER" | grep "^Version:" | awk '{print $2}')
    RELEASE=$(echo "$HEADER" | grep "^Release:" | awk '{print $2}' | sed 's/%{?dist}//')

    # Best-effort %{name} expansion using %global declarations from the spec.
    # Handles simple cases like `Version: %{major_version}.0` so local dev
    # without rpmspec works. Two passes to resolve nested macros.
    expand_macros() {
        local s=$1
        local i
        for i in 1 2; do
            while read -r macro_name macro_value; do
                [[ -z "$macro_name" ]] && continue
                s="${s//%\{${macro_name}\}/${macro_value}}"
            done < <(grep "^%global" "$SPEC_FILE" | awk '{print $2, $3}')
        done
        echo "$s"
    }
    VERSION=$(expand_macros "$VERSION")
    RELEASE=$(expand_macros "$RELEASE")
fi

if [[ -z "$VERSION" ]]; then
    echo "ERROR: Could not parse version from $SPEC_FILE" >&2
    exit 1
fi

echo "${VERSION}-${RELEASE}"

#!/bin/bash
# Script to check if packages need rebuilding by comparing spec versions with COPR versions
# Usage: ./check-copr-versions.sh [package1 package2 ...] or no args to check all packages

set -euo pipefail

COPR_OWNER="binarypie"
COPR_PROJECT="hypercube"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="$(cd "$SCRIPT_DIR/../../packages" && pwd)"

# Source shared configuration
source "$SCRIPT_DIR/config.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to get version from spec file (uses shared script)
get_spec_version() {
    local pkg=$1
    "$SCRIPT_DIR/get-spec-version.sh" "$pkg"
}

# Function to get version from COPR API
get_copr_version() {
    local pkg=$1
    local api_url="https://copr.fedorainfracloud.org/api_3/package?ownername=$COPR_OWNER&projectname=$COPR_PROJECT&packagename=$pkg&with_latest_build=True"

    # Query COPR API
    local response=$(curl -sf "$api_url" 2>/dev/null)

    if [[ -z "$response" ]]; then
        echo "ERROR: Failed to query COPR API for $pkg" >&2
        return 1
    fi

    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        echo "ERROR: jq is required but not installed" >&2
        return 1
    fi

    # Extract latest_succeeded build version
    local latest_succeeded=$(echo "$response" | jq -r '.builds.latest_succeeded' 2>/dev/null)

    if [[ -n "$latest_succeeded" && "$latest_succeeded" != "null" ]]; then
        # Extract version from source_package
        local version=$(echo "$latest_succeeded" | jq -r '.source_package.version' 2>/dev/null)

        if [[ -n "$version" && "$version" != "null" ]]; then
            echo "$version"
            return 0
        fi
    fi

    # Fallback: latest_succeeded is null (likely a build is running)
    # Query the build list to find the most recent successful build
    local build_list_url="https://copr.fedorainfracloud.org/api_3/build/list?ownername=$COPR_OWNER&projectname=$COPR_PROJECT&packagename=$pkg"
    local build_list=$(curl -sf "$build_list_url" 2>/dev/null)

    if [[ -z "$build_list" ]]; then
        echo "NOT_FOUND"
        return 0
    fi

    # Find first succeeded build in the list
    local version=$(echo "$build_list" | jq -r '.items[] | select(.state == "succeeded") | .source_package.version' 2>/dev/null | head -1)

    if [[ -z "$version" || "$version" == "null" ]]; then
        echo "NOT_FOUND"
        return 0
    fi

    echo "$version"
}

# Function to check a single package
check_package() {
    local pkg=$1
    local spec_ver copr_ver

    printf "${BLUE}Checking $pkg...${NC}\n"

    # Get spec version
    if ! spec_ver=$(get_spec_version "$pkg"); then
        printf "  ${RED}✗ Failed to get spec version${NC}\n"
        return 1
    fi
    printf "  Spec:     %s\n" "$spec_ver"

    # Get COPR version
    if ! copr_ver=$(get_copr_version "$pkg"); then
        printf "  ${RED}✗ Failed to get COPR version${NC}\n"
        return 1
    fi

    if [[ "$copr_ver" == "NOT_FOUND" ]]; then
        printf "  COPR:     ${YELLOW}No successful builds${NC}\n"
        printf "  ${YELLOW}⚠ Needs build (not in COPR)${NC}\n\n"
        return 2  # Return 2 to indicate needs build
    fi

    printf "  COPR:     %s\n" "$copr_ver"

    # Compare versions
    if [[ "$spec_ver" == "$copr_ver" ]]; then
        printf "  ${GREEN}✓ Versions match${NC}\n\n"
        return 0
    else
        printf "  ${YELLOW}⚠ Versions differ - needs build${NC}\n\n"
        return 2  # Return 2 to indicate needs build
    fi
}

# Main logic
main() {
    local packages=()
    local needs_build=()
    local up_to_date=()
    local errors=()

    # Determine which packages to check
    if [[ $# -eq 0 ]]; then
        # No arguments - check all packages
        echo "Checking all packages in $PACKAGES_DIR"
        echo ""
        for dir in "$PACKAGES_DIR"/*/; do
            pkg=$(basename "$dir")
            if [[ -f "$dir/$pkg.spec" ]]; then
                packages+=("$pkg")
            fi
        done
    else
        # Check specified packages
        packages=("$@")
    fi

    # Check each package
    for pkg in "${packages[@]}"; do
        if check_package "$pkg"; then
            up_to_date+=("$pkg")
        else
            case $? in
                1)
                    errors+=("$pkg")
                    ;;
                2)
                    needs_build+=("$pkg")
                    ;;
            esac
        fi
    done

    # Summary
    echo "=========================================="
    echo "Summary:"
    echo "=========================================="

    if [[ ${#up_to_date[@]} -gt 0 ]]; then
        printf "${GREEN}Up to date (${#up_to_date[@]}):${NC}\n"
        for pkg in "${up_to_date[@]}"; do
            printf "  - %s\n" "$pkg"
        done
        echo ""
    fi

    if [[ ${#needs_build[@]} -gt 0 ]]; then
        printf "${YELLOW}Needs build (${#needs_build[@]}):${NC}\n"
        for pkg in "${needs_build[@]}"; do
            printf "  - %s\n" "$pkg"
        done
        echo ""
    fi

    if [[ ${#errors[@]} -gt 0 ]]; then
        printf "${RED}Errors (${#errors[@]}):${NC}\n"
        for pkg in "${errors[@]}"; do
            printf "  - %s\n" "$pkg"
        done
        echo ""
    fi

    # Exit with appropriate code
    if [[ ${#errors[@]} -gt 0 ]]; then
        exit 1
    elif [[ ${#needs_build[@]} -gt 0 ]]; then
        # Output JSON array of packages that need building for easy parsing
        printf "NEEDS_BUILD_JSON="
        printf '%s\n' "${needs_build[@]}" | jq -R . | jq -sc .
        exit 0
    else
        echo "All packages are up to date!"
        exit 0
    fi
}

main "$@"

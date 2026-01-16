#!/bin/bash
# Check for upstream version updates by comparing spec versions with GitHub releases

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 [package1 package2 ...] or no args to check all packages"
    echo ""
    echo "Check for upstream version updates."
    echo ""
    echo "Options:"
    echo "  --json    Output results as JSON"
    exit 1
}

OUTPUT_JSON=false
PACKAGES_TO_CHECK=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            OUTPUT_JSON=true
            shift
            ;;
        --help|-h)
            usage
            ;;
        *)
            PACKAGES_TO_CHECK+=("$1")
            shift
            ;;
    esac
done

# Check a single package
check_package() {
    local pkg=$1

    # Get spec version
    local spec_ver
    if ! spec_ver=$("$SCRIPT_DIR/get-spec-version.sh" "$pkg" 2>/dev/null); then
        if [[ $OUTPUT_JSON == false ]]; then
            printf "${RED}✗ $pkg: Failed to get spec version${NC}\n" >&2
        fi
        return 1
    fi

    # Get upstream version
    local upstream_ver
    if ! upstream_ver=$("$SCRIPT_DIR/get-upstream-version.sh" "$pkg" 2>/dev/null); then
        if [[ $OUTPUT_JSON == false ]]; then
            printf "${RED}✗ $pkg: Failed to get upstream version${NC}\n" >&2
        fi
        return 1
    fi

    # Extract just version (remove -release suffix from spec)
    local spec_version_only="${spec_ver%-*}"

    if [[ $OUTPUT_JSON == true ]]; then
        # Output JSON object
        jq -n \
            --arg pkg "$pkg" \
            --arg spec "$spec_version_only" \
            --arg upstream "$upstream_ver" \
            --arg repo "${PACKAGE_REPOS[$pkg]}" \
            --arg deps "${PACKAGE_DEPS[$pkg]:-}" \
            '{package: $pkg, spec_version: $spec, upstream_version: $upstream, repo: $repo, dependencies: $deps, needs_update: ($spec != $upstream)}'
    else
        # Human-readable output
        if [[ "$spec_version_only" == "$upstream_ver" ]]; then
            printf "${GREEN}✓ %-30s spec: %-12s upstream: %-12s${NC}\n" "$pkg" "$spec_version_only" "$upstream_ver"
            return 0
        else
            printf "${YELLOW}⚠ %-30s spec: %-12s upstream: %-12s (UPDATE AVAILABLE)${NC}\n" "$pkg" "$spec_version_only" "$upstream_ver"
            return 2
        fi
    fi
}

# Main logic
main() {
    local packages=()
    local updates_available=()
    local up_to_date=()
    local errors=()

    # Determine which packages to check
    if [[ ${#PACKAGES_TO_CHECK[@]} -eq 0 ]]; then
        # No arguments - check all packages that have upstream repos
        packages=("${!PACKAGE_REPOS[@]}")
    else
        packages=("${PACKAGES_TO_CHECK[@]}")
    fi

    if [[ $OUTPUT_JSON == true ]]; then
        echo "["
        first=true
        for pkg in "${packages[@]}"; do
            if [[ $first == false ]]; then
                echo ","
            fi
            first=false
            check_package "$pkg" || true
        done
        echo ""
        echo "]"
    else
        echo "Checking for upstream updates..."
        echo ""

        for pkg in "${packages[@]}"; do
            if check_package "$pkg"; then
                up_to_date+=("$pkg")
            else
                case $? in
                    1)
                        errors+=("$pkg")
                        ;;
                    2)
                        updates_available+=("$pkg")
                        ;;
                esac
            fi
        done

        echo ""
        echo "=========================================="
        echo "Summary:"
        echo "=========================================="

        if [[ ${#up_to_date[@]} -gt 0 ]]; then
            printf "${GREEN}Up to date (${#up_to_date[@]}):${NC} ${up_to_date[*]}\n"
            echo ""
        fi

        if [[ ${#updates_available[@]} -gt 0 ]]; then
            printf "${YELLOW}Updates available (${#updates_available[@]}):${NC}\n"
            for pkg in "${updates_available[@]}"; do
                printf "  - %s\n" "$pkg"
            done
            echo ""
        fi

        if [[ ${#errors[@]} -gt 0 ]]; then
            printf "${RED}Errors (${#errors[@]}):${NC} ${errors[*]}\n"
            echo ""
        fi

        # Exit with appropriate code
        if [[ ${#errors[@]} -gt 0 ]]; then
            exit 1
        elif [[ ${#updates_available[@]} -gt 0 ]]; then
            exit 0
        else
            exit 0
        fi
    fi
}

main

#!/bin/bash
# Script to check if packages need rebuilding by comparing spec versions with COPR versions
# Usage: ./check-copr-versions.sh [package1 package2 ...] or no args to check all packages
#
# A package is up-to-date only if EVERY enabled chroot in the Copr project has
# a successful build at the spec version. If any chroot is missing, failed, or
# behind, the package is flagged for rebuild.

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

if ! command -v jq &> /dev/null; then
    echo "ERROR: jq is required but not installed" >&2
    exit 1
fi

# Function to get version from spec file (uses shared script)
get_spec_version() {
    local pkg=$1
    "$SCRIPT_DIR/get-spec-version.sh" "$pkg"
}

# Fetched once at script start and reused per-package.
ENABLED_CHROOTS=""
MONITOR_JSON=""

fetch_project_state() {
    local project_url="https://copr.fedorainfracloud.org/api_3/project?ownername=$COPR_OWNER&projectname=$COPR_PROJECT"
    local monitor_url="https://copr.fedorainfracloud.org/api_3/monitor?ownername=$COPR_OWNER&projectname=$COPR_PROJECT"

    local project_json
    if ! project_json=$(curl -sf "$project_url"); then
        echo "ERROR: Failed to query Copr project info" >&2
        return 1
    fi
    ENABLED_CHROOTS=$(echo "$project_json" | jq -r '.chroot_repos | keys[]' | tr '\n' ' ')

    if ! MONITOR_JSON=$(curl -sf "$monitor_url"); then
        echo "ERROR: Failed to query Copr monitor" >&2
        return 1
    fi
}

# Look up the per-chroot state of a package from the monitor response.
# Echoes `<state>|<pkg_version>` or empty if no entry exists.
get_chroot_state() {
    local pkg=$1
    local chroot=$2
    echo "$MONITOR_JSON" | jq -r --arg p "$pkg" --arg c "$chroot" '
        (.packages[] | select(.name == $p) | .chroots[$c]) as $e
        | if $e == null then "" else "\($e.state)|\($e.pkg_version)" end
    '
}

# Function to check a single package against every enabled chroot.
check_package() {
    local pkg=$1
    local spec_ver

    printf "${BLUE}Checking $pkg...${NC}\n"

    if ! spec_ver=$(get_spec_version "$pkg"); then
        printf "  ${RED}✗ Failed to get spec version${NC}\n"
        return 1
    fi
    printf "  Spec:     %s\n" "$spec_ver"

    local needs_build=false
    local reasons=""

    for chroot in $ENABLED_CHROOTS; do
        local entry state copr_ver
        entry=$(get_chroot_state "$pkg" "$chroot")

        if [[ -z "$entry" ]]; then
            printf "  %-22s ${YELLOW}no build${NC}\n" "$chroot"
            needs_build=true
            reasons="$reasons $chroot(missing)"
            continue
        fi

        state="${entry%%|*}"
        copr_ver="${entry##*|}"

        if [[ "$state" != "succeeded" ]]; then
            printf "  %-22s ${YELLOW}%s (last: %s)${NC}\n" "$chroot" "$state" "$copr_ver"
            needs_build=true
            reasons="$reasons $chroot($state)"
        elif [[ "$spec_ver" != "$copr_ver" ]]; then
            printf "  %-22s ${YELLOW}%s${NC} (spec %s)\n" "$chroot" "$copr_ver" "$spec_ver"
            needs_build=true
            reasons="$reasons $chroot(behind:$copr_ver)"
        else
            printf "  %-22s ${GREEN}%s${NC}\n" "$chroot" "$copr_ver"
        fi
    done

    if [[ "$needs_build" == "true" ]]; then
        printf "  ${YELLOW}⚠ Needs build:${reasons}${NC}\n\n"
        return 2
    fi

    printf "  ${GREEN}✓ All chroots up to date${NC}\n\n"
    return 0
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

    # Fetch project chroots and monitor state once for all packages.
    if ! fetch_project_state; then
        exit 1
    fi
    echo "Enabled chroots: $ENABLED_CHROOTS"
    echo ""

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

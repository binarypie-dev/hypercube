#!/bin/bash
# Test script for check-copr-versions.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK_SCRIPT="$SCRIPT_DIR/check-copr-versions.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

test_count=0
pass_count=0

run_test() {
    local test_name=$1
    shift
    local expected_exit=$1
    shift

    test_count=$((test_count + 1))

    echo "Test $test_count: $test_name"

    set +e
    output=$("$CHECK_SCRIPT" "$@" 2>&1)
    exit_code=$?
    set -e

    if [[ $exit_code -eq $expected_exit ]]; then
        printf "  ${GREEN}✓ PASS${NC}\n"
        pass_count=$((pass_count + 1))
    else
        printf "  ${RED}✗ FAIL${NC} (expected exit code $expected_exit, got $exit_code)\n"
        echo "Output:"
        echo "$output"
    fi
    echo ""
}

echo "Running tests for check-copr-versions.sh"
echo "=========================================="
echo ""

# Test 1: Check packages that should be up to date
run_test "Check up-to-date packages (starship, uwsm, lazygit)" 0 starship uwsm lazygit

# Test 2: Check a package that needs building (if any)
# This test might be flaky if all packages are up to date
run_test "Check all packages" 0

# Test 3: Check nonexistent package (should fail)
set +e
"$CHECK_SCRIPT" nonexistent-package-12345 >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
    test_count=$((test_count + 1))
    pass_count=$((pass_count + 1))
    printf "Test $test_count: Nonexistent package should fail\n"
    printf "  ${GREEN}✓ PASS${NC}\n\n"
else
    test_count=$((test_count + 1))
    printf "Test $test_count: Nonexistent package should fail\n"
    printf "  ${RED}✗ FAIL${NC}\n\n"
fi
set -e

# Test 4: Verify jq is available
if command -v jq &> /dev/null; then
    test_count=$((test_count + 1))
    pass_count=$((pass_count + 1))
    printf "Test $test_count: jq is available\n"
    printf "  ${GREEN}✓ PASS${NC}\n\n"
else
    test_count=$((test_count + 1))
    printf "Test $test_count: jq is available\n"
    printf "  ${RED}✗ FAIL${NC} (jq not found)\n\n"
fi

# Summary
echo "=========================================="
echo "Test Results: $pass_count/$test_count passed"
echo "=========================================="

if [[ $pass_count -eq $test_count ]]; then
    printf "${GREEN}All tests passed!${NC}\n"
    exit 0
else
    printf "${RED}Some tests failed${NC}\n"
    exit 1
fi

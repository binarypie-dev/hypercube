#!/bin/bash
# Test suite for get-spec-version.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/get-spec-version.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

test_count=0
pass_count=0

run_test() {
    local test_name=$1
    local expected=$2
    local package=$3

    test_count=$((test_count + 1))

    echo "Test $test_count: $test_name"

    set +e
    output=$("$SCRIPT" "$package" 2>&1)
    exit_code=$?
    set -e

    if [[ $exit_code -eq 0 && "$output" == "$expected" ]]; then
        printf "  ${GREEN}✓ PASS${NC} (got: $output)\n"
        pass_count=$((pass_count + 1))
    else
        printf "  ${RED}✗ FAIL${NC} (expected: $expected, got: $output, exit: $exit_code)\n"
    fi
    echo ""
}

echo "Running tests for get-spec-version.sh"
echo "=========================================="
echo ""

# Test 1: Get version for starship
run_test "Get starship version" "1.24.2-1" "starship"

# Test 2: Get version for lazygit
run_test "Get lazygit version" "0.58.1-1" "lazygit"

# Test 3: Nonexistent package should fail
test_count=$((test_count + 1))
set +e
"$SCRIPT" "nonexistent-package-xyz" >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
    printf "Test $test_count: Nonexistent package should fail\n"
    printf "  ${GREEN}✓ PASS${NC}\n\n"
    pass_count=$((pass_count + 1))
else
    printf "Test $test_count: Nonexistent package should fail\n"
    printf "  ${RED}✗ FAIL${NC}\n\n"
fi
set -e

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

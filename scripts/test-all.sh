#!/bin/bash
# Run all script tests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

total_tests=0
total_passed=0
total_failed=0

run_test_suite() {
    local test_file=$1
    local test_name=$(basename "$test_file")

    printf "${BLUE}Running $test_name...${NC}\n"

    if "$test_file"; then
        printf "${GREEN}✓ $test_name passed${NC}\n\n"
        return 0
    else
        printf "${RED}✗ $test_name failed${NC}\n\n"
        return 1
    fi
}

# Find and run all test scripts recursively
while IFS= read -r -d '' test_script; do
    total_tests=$((total_tests + 1))
    if run_test_suite "$test_script"; then
        total_passed=$((total_passed + 1))
    else
        total_failed=$((total_failed + 1))
    fi
done < <(find "$SCRIPT_DIR" -type f -name 'test-*.sh' ! -name 'test-all.sh' -executable -print0)

echo "=========================================="
echo "Overall Test Results:"
echo "=========================================="
printf "Total: %d  " "$total_tests"
printf "${GREEN}Passed: %d${NC}  " "$total_passed"
printf "${RED}Failed: %d${NC}\n" "$total_failed"

if [[ $total_failed -eq 0 ]]; then
    printf "\n${GREEN}All test suites passed!${NC}\n"
    exit 0
else
    printf "\n${RED}Some test suites failed${NC}\n"
    exit 1
fi

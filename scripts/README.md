# Scripts

This directory contains scripts organized by purpose:

- **packages/** - Package management scripts (version checking, COPR builds, etc.)
- **test-all.sh** - Runs all test scripts across subdirectories

## Package Scripts (`packages/`)

### config.sh

Shared configuration file containing package metadata, dependencies, and build order.

**Contents:**
- `PACKAGE_REPOS` - Upstream GitHub repositories
- `VERSION_SOURCES` - Where to check for versions (release/tag)
- `PACKAGE_DEPS` - Package dependencies for build order
- `BUILD_BATCHES` - Build order batches

This file is sourced by other scripts to maintain consistency.

### get-spec-version.sh

Gets the version from a package's spec file.

**Usage:**
```bash
./scripts/packages/get-spec-version.sh starship
# Output: 1.24.2-1
```

### get-upstream-version.sh

Gets the latest upstream version from GitHub (releases or tags).

**Usage:**
```bash
./scripts/packages/get-upstream-version.sh starship
# Output: 1.24.2
```

**Note:** Uses `gh` CLI if authenticated, otherwise falls back to curl (subject to GitHub API rate limits).

### check-copr-versions.sh

Compares package versions in spec files against what's currently built in COPR to determine which packages need rebuilding.

### Usage

```bash
# Check all packages
./scripts/packages/check-copr-versions.sh

# Check specific packages
./scripts/packages/check-copr-versions.sh starship lazygit uwsm

# Use in scripts (capture JSON output)
output=$(./scripts/packages/check-copr-versions.sh starship lazygit 2>&1)
needs_build=$(echo "$output" | grep "^NEEDS_BUILD_JSON=" | sed 's/^NEEDS_BUILD_JSON=//')
```

### Requirements

- `curl` - for querying COPR API
- `jq` - for JSON parsing

### Exit Codes

- `0` - Success (all packages checked, some may need building)
- `1` - Error (failed to check one or more packages)

### Output

The script provides:
- Colored output showing each package check
- Summary of up-to-date vs needs-build packages
- `NEEDS_BUILD_JSON` array for easy parsing in workflows

### How It Works

1. Reads `Version` and `Release` from each package's spec file
2. Queries COPR API for the latest successful build
3. If `latest_succeeded` is null (e.g., a build is running), falls back to querying the build list
4. Compares versions and determines if a rebuild is needed

### Testing

Run the test suite:

```bash
./scripts/packages/test-check-copr-versions.sh
```

### check-upstream-versions.sh

Checks for upstream version updates by comparing spec versions with GitHub releases.

**Usage:**
```bash
# Check all packages
./scripts/packages/check-upstream-versions.sh

# Check specific packages
./scripts/packages/check-upstream-versions.sh starship lazygit

# JSON output for automation
./scripts/packages/check-upstream-versions.sh --json
```

**Requirements:**
- `curl` or `gh` CLI - for querying GitHub
- `jq` - for JSON parsing

**Output:**
- Human-readable colored output showing version comparisons
- JSON output with `--json` flag for workflow integration

## Test Scripts

All test scripts can be run individually or via the master test runner:

```bash
# Run all tests
./scripts/test-all.sh

# Run specific test
./scripts/packages/test-check-copr-versions.sh
./scripts/packages/test-get-spec-version.sh
./scripts/packages/test-get-upstream-version.sh
```

### test-check-copr-versions.sh

Test suite for `check-copr-versions.sh` that verifies:
- Up-to-date packages are correctly identified
- Script handles nonexistent packages gracefully
- Required dependencies (jq) are available

## Architecture

The scripts are organized with shared logic:

```
scripts/
├── packages/                          # Package management scripts
│   ├── config.sh                      # Shared configuration
│   ├── get-spec-version.sh            # Parse spec files
│   ├── get-upstream-version.sh        # Query GitHub
│   ├── check-copr-versions.sh         # Compare with COPR
│   ├── check-upstream-versions.sh     # Compare with upstream
│   └── test-*.sh                      # Test suites
└── test-all.sh                        # Master test runner
```

This modular approach:
- **Organized namespaces** - Package scripts separate from other scripts
- **Reduces duplication** - Configuration in one place
- **Improves maintainability** - Easy to update package lists
- **Enables testing** - Scripts can be tested locally
- **Simplifies workflows** - Workflows call scripts instead of inline logic

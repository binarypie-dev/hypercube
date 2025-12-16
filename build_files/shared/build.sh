#!/bin/bash
# Hypercube Build Orchestrator
# Main build script that coordinates all build steps

set -ouex pipefail

echo "========================================"
echo "Starting Hypercube Build"
echo "========================================"

### Rsync system files to root filesystem
echo "Installing system files..."
# Note: We don't use --ignore-existing so our files override base image files
rsync -rlpvh /ctx/system_files/shared/ /

### Run hypercube build scripts in order
echo "Running build scripts..."
for script in /ctx/build_files/hypercube/*.sh; do
    if [[ -f "$script" && -x "$script" ]]; then
        echo ""
        echo "========================================"
        echo "Running: $(basename "$script")"
        echo "========================================"
        "$script"
    fi
done

### Final cleanup
echo ""
echo "========================================"
echo "Running cleanup..."
echo "========================================"
/ctx/build_files/shared/clean-stage.sh

echo ""
echo "========================================"
echo "Hypercube Build Complete!"
echo "========================================"

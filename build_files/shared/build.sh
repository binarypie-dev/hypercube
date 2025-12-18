#!/bin/bash
# Hypercube v2 Build Orchestrator
# Main build script that coordinates all build steps

set -ouex pipefail

echo "========================================"
echo "Starting Hypercube v2 Build"
echo "========================================"

### Rsync system files to root filesystem
echo "Installing system files..."
# Note: We don't use --ignore-existing so our files override base image files
rsync -rlpvh /ctx/system_files/shared/ /

### Run build scripts in order from each phase directory
# Phase 1: Base system (greetd, portals, hardware)
# Phase 2: Hyprland desktop
# Phase 3: DX tooling
# Phase 4: Hypercube theming/branding

BUILD_DIRS=(
    "/ctx/build_files/base"
    "/ctx/build_files/hyprland"
    "/ctx/build_files/dx"
    "/ctx/build_files/hypercube"
)

for build_dir in "${BUILD_DIRS[@]}"; do
    if [[ -d "$build_dir" ]]; then
        for script in "$build_dir"/*.sh; do
            if [[ -f "$script" && -x "$script" ]]; then
                echo ""
                echo "========================================"
                echo "Running: $(basename "$build_dir")/$(basename "$script")"
                echo "========================================"
                "$script"
            fi
        done
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
echo "Hypercube v2 Build Complete!"
echo "========================================"

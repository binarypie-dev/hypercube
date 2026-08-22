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

### Prime the SELinux policy store into the overlay upper layer
# semodule commits changes with rename(active, previous)+rename(tmp, active).
# When `active` is inherited from a lower overlay layer (as it is fresh from
# the base image), the first rename fails with EXDEV; libsemanage falls back
# to a non-atomic *copy* that leaves `active` in place, so the second rename
# then aborts with "Directory not empty". This makes semodule flaky/failing
# for every transaction in the build -- package %post scriptlets that ship
# SELinux policy (nvidia-driver-selinux, greetd-selinux) and our own
# hypercube-greeter module. Copying `active` onto itself pulls the store fully
# into this layer's upper dir so all renames stay within one layer and every
# semodule call commits cleanly. See SELinuxProject/selinux#343.
SELINUX_STORE="/etc/selinux/targeted"
if [[ -d "${SELINUX_STORE}/active" ]]; then
    echo "Priming SELinux policy store into overlay upper layer..."
    rm -rf "${SELINUX_STORE}/tmp" "${SELINUX_STORE}/previous"
    cp -a "${SELINUX_STORE}/active" "${SELINUX_STORE}/active.copyup"
    rm -rf "${SELINUX_STORE}/active"
    mv "${SELINUX_STORE}/active.copyup" "${SELINUX_STORE}/active"
fi

### Run build scripts in order from each phase directory
# Phase 1: Base system (greetd, portals, hardware)
# Phase 2: Hyprland desktop
# Phase 3: DX tooling
# Phase 4: Hypercube theming/branding

BUILD_DIRS=(
    "/ctx/build_files/base"
    "/ctx/build_files/hyprland"
    "/ctx/build_files/dx"
    "/ctx/build_files/apps"
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

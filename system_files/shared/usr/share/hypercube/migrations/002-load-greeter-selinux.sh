#!/bin/bash
# Migration: load the hypercube-greeter SELinux policy module.
#
# The module is compiled at image build time (build_files/base/01-base-system.sh)
# but intentionally not installed then: semodule's policy-store commit is
# unreliable under the build's overlayfs (rename(active, previous) hits EXDEV
# and the non-atomic fallback corrupts the store once earlier package %post
# scriptlets have run -- see SELinuxProject/selinux#343). At boot the store is
# on a normal filesystem, so loading works reliably. This migration runs
# Before=greetd.service, so the policy is active before the greeter starts.

set -euo pipefail

MODULE="/usr/share/hypercube/selinux/hypercube-greeter.pp"

# Nothing to do if the compiled module is missing.
[[ -f "$MODULE" ]] || exit 0

# Idempotent: skip if the module is already loaded.
if semodule -l 2>/dev/null | grep -qw hypercube-greeter; then
    exit 0
fi

echo "Loading hypercube-greeter SELinux policy module..."
semodule -i "$MODULE"
echo "hypercube-greeter SELinux module loaded"

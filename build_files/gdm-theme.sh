#!/bin/bash
# Hypercube GDM Theme Installation
# Modifies gnome-shell-theme.gresource to customize GDM login screen
#
# This script extracts the GNOME Shell theme gresource, patches the CSS
# to use our custom background, and recompiles it.

set -euo pipefail

GRESOURCE="/usr/share/gnome-shell/gnome-shell-theme.gresource"
WORKDIR="/var/tmp/gdm-theme-workdir"
LOGO_PATH="/usr/share/pixmaps/hypercube-logo.png"

echo "Installing Hypercube GDM theme..."

# Verify required files exist
if [ ! -f "$GRESOURCE" ]; then
    echo "ERROR: $GRESOURCE not found"
    exit 1
fi

if [ ! -f "$LOGO_PATH" ]; then
    echo "ERROR: $LOGO_PATH not found"
    exit 1
fi

# Verify gresource tools are available
if ! command -v gresource &> /dev/null; then
    echo "ERROR: gresource command not found. Install glib2-devel."
    exit 1
fi

if ! command -v glib-compile-resources &> /dev/null; then
    echo "ERROR: glib-compile-resources command not found. Install glib2-devel."
    exit 1
fi

# Create working directory
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR/theme"

# Extract all resources from the gresource file
echo "Extracting gnome-shell-theme.gresource..."
for resource in $(gresource list "$GRESOURCE"); do
    # Remove /org/gnome/shell/ prefix for local path
    local_path="${resource#/org/gnome/shell/}"
    mkdir -p "$WORKDIR/$(dirname "$local_path")"
    gresource extract "$GRESOURCE" "$resource" > "$WORKDIR/$local_path"
done

# Copy our logo to the theme directory so it can be embedded
cp "$LOGO_PATH" "$WORKDIR/theme/hypercube-logo.png"

# Patch the CSS files to use our custom background
# We need to modify both light and dark variants
for css_file in "$WORKDIR/theme/gnome-shell.css" "$WORKDIR/theme/gnome-shell-light.css" "$WORKDIR/theme/gnome-shell-dark.css"; do
    if [ -f "$css_file" ]; then
        echo "Patching $(basename "$css_file")..."

        # Replace the #lockDialogGroup background
        # The original typically has: background-color: $system_bg_color; or similar
        # We replace any existing #lockDialogGroup block with our custom one

        if grep -q '#lockDialogGroup' "$css_file"; then
            # Use sed to replace the existing #lockDialogGroup block
            # This handles multi-line blocks by replacing just the background property
            sed -i 's|#lockDialogGroup {|#lockDialogGroup { background: #000000 url(resource:///org/gnome/shell/theme/hypercube-logo.png) no-repeat center center; background-size: auto;|' "$css_file"
            # Remove any duplicate/old background properties that might conflict
            sed -i '/#lockDialogGroup/,/}/ { /background-color:/d; }' "$css_file"
        else
            # If #lockDialogGroup doesn't exist, append it
            echo '
#lockDialogGroup {
    background: #000000 url(resource:///org/gnome/shell/theme/hypercube-logo.png) no-repeat center center;
    background-size: auto;
}' >> "$css_file"
        fi
    fi
done

# Create the gresource XML manifest
echo "Creating gresource manifest..."
cat > "$WORKDIR/gnome-shell-theme.gresource.xml" << 'XMLEOF'
<?xml version="1.0" encoding="UTF-8"?>
<gresources>
  <gresource prefix="/org/gnome/shell/theme">
XMLEOF

# Add all files in theme directory to the manifest
find "$WORKDIR/theme" -type f | while read -r file; do
    relpath="${file#$WORKDIR/theme/}"
    echo "    <file>theme/$relpath</file>" >> "$WORKDIR/gnome-shell-theme.gresource.xml"
done

cat >> "$WORKDIR/gnome-shell-theme.gresource.xml" << 'XMLEOF'
  </gresource>
</gresources>
XMLEOF

# Compile the new gresource
echo "Compiling new gresource..."
cd "$WORKDIR"
glib-compile-resources gnome-shell-theme.gresource.xml --target=gnome-shell-theme.gresource

# Backup original and install new gresource
# Use cp instead of mv to avoid SELinux issues
echo "Installing new gresource..."
cp "$GRESOURCE" "${GRESOURCE}.backup"
cp "$WORKDIR/gnome-shell-theme.gresource" "$GRESOURCE"

# Cleanup
rm -rf "$WORKDIR"

echo "Hypercube GDM theme installed successfully"

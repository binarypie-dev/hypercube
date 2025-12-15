# Hypercube Custom Commands

# Reset user configs to Hypercube defaults
hypercube-config-reset:
    #!/usr/bin/bash
    set -euo pipefail

    echo "Hypercube Config Reset"
    echo "======================"
    echo ""
    echo "This will:"
    echo "  1. Archive your existing configs to ~/.config/hypercube-backup-<timestamp>/"
    echo "  2. Create new config stubs that source Hypercube system defaults"
    echo ""
    echo "Configs that will be reset:"
    echo "  - Ghostty (~/.config/ghostty/)"
    echo "  - Wezterm (~/.config/wezterm/)"
    echo ""
    echo "You can restore your old configs from the backup directory at any time."
    echo ""

    read -p "Continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi

    # Create backup directory with timestamp
    BACKUP_DIR="$HOME/.config/hypercube-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    echo ""
    echo "Created backup directory: $BACKUP_DIR"

    # Function to backup and reset a config
    backup_and_reset() {
        local config_path="$1"
        local config_name="$2"

        if [[ -e "$HOME/.config/$config_path" ]]; then
            echo "  Backing up $config_name..."
            mkdir -p "$BACKUP_DIR/$(dirname "$config_path")"
            mv "$HOME/.config/$config_path" "$BACKUP_DIR/$config_path"
        fi
    }

    echo ""
    echo "Backing up existing configs..."

    # Backup existing configs
    backup_and_reset "ghostty" "Ghostty"
    backup_and_reset "wezterm" "Wezterm"

    echo ""
    echo "Creating Hypercube config stubs..."

    # Create Ghostty stub
    mkdir -p "$HOME/.config/ghostty"
    cat > "$HOME/.config/ghostty/config" << 'EOF'
# Hypercube Ghostty Configuration
# System defaults are sourced below. Add your customizations after this line.
# To replace defaults entirely, remove or comment out the config-file line.

config-file = /usr/share/hypercube/config/ghostty/config

# Your customizations below:
EOF
    echo "  Created Ghostty config stub"

    # Create Wezterm stub
    mkdir -p "$HOME/.config/wezterm"
    cat > "$HOME/.config/wezterm/wezterm.lua" << 'EOF'
-- Hypercube Wezterm Configuration
-- System defaults are loaded below. Add your customizations after this line.
-- To replace defaults entirely, remove the dofile line and start fresh.

local config = dofile("/usr/share/hypercube/config/wezterm/wezterm.lua")

-- Your customizations below:
-- Example: config.font_size = 14

return config
EOF
    echo "  Created Wezterm config stub"

    echo ""
    echo "Done! Your old configs have been backed up to:"
    echo "  $BACKUP_DIR"
    echo ""
    echo "Your new configs source Hypercube system defaults."
    echo "Add any customizations after the source/config-file line in each config."

# vim: set ft=make :
# Hypercube general commands

# Reset Hypercube configs to defaults (backs up existing configs first)
config-reset APP="all":
    #!/usr/bin/bash
    set -euo pipefail

    SOURCE_DIR="/usr/share/hypercube/config"
    BACKUP_DIR="$HOME/.config/hypercube-backup-$(date +%Y%m%d-%H%M%S)"

    # Map app names to config directories/files
    declare -A CONFIG_MAP
    CONFIG_MAP[hypr]="hypr"
    CONFIG_MAP[fish]="fish"
    CONFIG_MAP[ghostty]="ghostty"
    CONFIG_MAP[nvim]="nvim"
    CONFIG_MAP[starship]="starship/starship.toml"
    CONFIG_MAP[quickshell]="quickshell"

    reset_config() {
        local app="$1"
        local config_path="${CONFIG_MAP[$app]}"

        if [[ -z "$config_path" ]]; then
            echo "Unknown app: $app"
            echo "Available: ${!CONFIG_MAP[*]}"
            return 1
        fi

        local src="$SOURCE_DIR/$config_path"
        local dest="$HOME/.config/$config_path"

        if [[ ! -e "$src" ]]; then
            echo "Source config not found: $src"
            return 1
        fi

        # Backup existing config if it exists
        if [[ -e "$dest" ]]; then
            mkdir -p "$BACKUP_DIR"
            echo "Backing up $dest -> $BACKUP_DIR/$config_path"
            cp -r "$dest" "$BACKUP_DIR/$config_path"
        fi

        # Copy new config
        echo "Resetting $app config..."
        mkdir -p "$(dirname "$dest")"
        rm -rf "$dest"
        cp -r "$src" "$dest"
        echo "  Done!"
    }

    if [[ "{{ APP }}" == "all" ]]; then
        echo "Resetting all Hypercube configs..."
        echo "Backups will be saved to: $BACKUP_DIR"
        echo ""
        for app in "${!CONFIG_MAP[@]}"; do
            reset_config "$app"
        done
        echo ""
        echo "All configs reset! Backups saved to: $BACKUP_DIR"
    else
        reset_config "{{ APP }}"
        if [[ -d "$BACKUP_DIR" ]]; then
            echo ""
            echo "Backup saved to: $BACKUP_DIR"
        fi
    fi

# Show differences between current and default configs
config-diff APP="all":
    #!/usr/bin/bash
    set -euo pipefail

    SOURCE_DIR="/usr/share/hypercube/config"

    declare -A CONFIG_MAP
    CONFIG_MAP[hypr]="hypr"
    CONFIG_MAP[fish]="fish"
    CONFIG_MAP[ghostty]="ghostty"
    CONFIG_MAP[nvim]="nvim"
    CONFIG_MAP[starship]="starship/starship.toml"
    CONFIG_MAP[quickshell]="quickshell"

    diff_config() {
        local app="$1"
        local config_path="${CONFIG_MAP[$app]}"

        if [[ -z "$config_path" ]]; then
            echo "Unknown app: $app"
            echo "Available: ${!CONFIG_MAP[*]}"
            return 1
        fi

        local src="$SOURCE_DIR/$config_path"
        local dest="$HOME/.config/$config_path"

        echo "=== $app ==="
        if [[ ! -e "$dest" ]]; then
            echo "  (not installed - would copy from defaults)"
        elif [[ ! -e "$src" ]]; then
            echo "  (no default config found)"
        else
            if diff -rq "$src" "$dest" > /dev/null 2>&1; then
                echo "  (no differences)"
            else
                diff -r --color=auto "$src" "$dest" 2>/dev/null || true
            fi
        fi
        echo ""
    }

    if [[ "{{ APP }}" == "all" ]]; then
        echo "Comparing configs: ~/.config vs /usr/share/hypercube/config"
        echo ""
        for app in "${!CONFIG_MAP[@]}"; do
            diff_config "$app"
        done
    else
        diff_config "{{ APP }}"
    fi

# List available default configs
config-list:
    #!/usr/bin/bash
    echo "Available Hypercube configs:"
    echo ""
    echo "  hypr        - Hyprland window manager"
    echo "  fish        - Fish shell"
    echo "  ghostty     - Ghostty terminal"
    echo "  nvim        - Neovim editor"
    echo "  starship    - Starship prompt"
    echo "  quickshell  - Quickshell bar/launcher"
    echo ""
    echo "Usage:"
    echo "  ujust config-reset           # Reset all configs"
    echo "  ujust config-reset hypr      # Reset specific config"
    echo "  ujust config-diff            # Show all differences"
    echo "  ujust config-diff hypr       # Show specific differences"

# Show Hypercube developer environment status
dx-status:
    #!/usr/bin/bash
    set -euo pipefail

    echo "Hypercube DX Status"
    echo "==================="
    echo ""

    echo "Container Runtimes:"
    echo -n "  Podman: "
    podman --version 2>/dev/null || echo "not found"
    echo ""

    echo "Distrobox Containers:"
    distrobox list 2>/dev/null || echo "  (none)"

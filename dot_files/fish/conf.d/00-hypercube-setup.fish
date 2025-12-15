# Hypercube Fish Setup
# Ensures user has a writable fish config directory for fish_variables
# Fish writes universal variables to $__fish_config_dir/fish_variables
# Since system config is in /etc/fish, users need ~/.config/fish for writes

if status is-interactive
    # Create user's fish config directory if it doesn't exist
    set -l user_fish_dir "$HOME/.config/fish"
    if not test -d "$user_fish_dir"
        mkdir -p "$user_fish_dir"
    end
end

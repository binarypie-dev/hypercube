if status is-interactive
    # Commands to run in interactive sessions can go here

    # VIM Mode
    fish_vi_key_bindings

    # Editor
    set -gx EDITOR nvim

    # Prompt - Starship
    set -gx STARSHIP_CONFIG /usr/share/hypercube/config/starship/starship.toml
    starship init fish | source

    # Env Variables
    set -gx GOOGLE_CLOUD_PROJECT ibexio-src

    # Path
    fish_add_path $HOME/.local/bin
    fish_add_path $HOME/.npm-packages/bin
    fish_add_path $HOME/.cargo/bin
    fish_add_path $HOME/Code/flutter/bin
    fish_add_path $HOME/go/bin

    # Alias
    alias wezterm 'flatpak run org.wezfurlong.wezterm'
end

### bling.fish source start
test -f /usr/share/ublue-os/bluefin-cli/bling.fish && source /usr/share/ublue-os/bluefin-cli/bling.fish
### bling.fish source end

if status is-interactive
    # Commands to run in interactive sessions can go here

    # Disable greeting
    set -g fish_greeting

    # VIM Mode
    fish_vi_key_bindings

    # Editor
    set -gx EDITOR nvim

    # Prompt - Starship
    set -gx STARSHIP_CONFIG /usr/share/hypercube/config/starship/starship.toml
    starship init fish | source

    # Path
    fish_add_path $HOME/.local/bin
    fish_add_path $HOME/.npm-packages/bin
    fish_add_path $HOME/.cargo/bin
    fish_add_path $HOME/go/bin

end

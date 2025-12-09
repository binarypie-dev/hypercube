{ ... }:

{
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    prefix = "C-a";
    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 50000;
    mouse = true;
    terminal = "tmux-256color";
    extraConfig = ''
      # Vim-style pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Vim-style pane resizing
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # Vim-style copy mode
      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "wl-copy"
      bind -T copy-mode-vi C-v send-keys -X rectangle-toggle

      # Split panes using | and -
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Tokyo Night colors
      set -g status-style "fg=#7aa2f7,bg=#1a1b26"
      set -g status-left "#[fg=#1a1b26,bg=#7aa2f7,bold] #S "
      set -g status-right "#[fg=#c0caf5,bg=#1a1b26] %H:%M "
      set -g window-status-format "#[fg=#414868] #I:#W "
      set -g window-status-current-format "#[fg=#7aa2f7,bold] #I:#W "
      set -g pane-border-style "fg=#414868"
      set -g pane-active-border-style "fg=#7aa2f7"
    '';
  };
}

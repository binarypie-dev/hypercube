{ ... }:

{
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local wezterm = require 'wezterm'
      local config = wezterm.config_builder()

      -- Tokyo Night theme
      config.color_scheme = 'tokyonight_night'

      -- Font
      config.font = wezterm.font 'JetBrainsMono Nerd Font'
      config.font_size = 12.0

      -- Window
      config.window_background_opacity = 0.95
      config.window_decorations = "RESIZE"
      config.window_padding = {
        left = 10,
        right = 10,
        top = 10,
        bottom = 10,
      }

      -- Tab bar
      config.enable_tab_bar = true
      config.hide_tab_bar_if_only_one_tab = true
      config.use_fancy_tab_bar = false

      -- Misc
      config.scrollback_lines = 10000
      config.enable_scroll_bar = false
      config.default_prog = { 'fish' }

      return config
    '';
  };
}

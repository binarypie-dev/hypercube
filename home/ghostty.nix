{ ... }:

{
  programs.ghostty = {
    enable = true;
    settings = {
      theme = "tokyonight";
      font-family = "JetBrainsMono Nerd Font";
      font-size = 12;
      background-opacity = 0.95;
      window-decoration = false;
      shell-integration = "fish";
    };
  };
}

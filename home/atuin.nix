{ ... }:

{
  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      auto_sync = false;
      sync_frequency = "0";
      search_mode = "fuzzy";
      style = "compact";
      keymap_mode = "vim-normal";
    };
  };
}

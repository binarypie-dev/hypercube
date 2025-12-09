{ ... }:

{
  programs.starship = {
    enable = false; # Disabled in favor of hydro, enable if preferred
    settings = {
      format = "$all";
      palette = "tokyonight";

      palettes.tokyonight = {
        blue = "#7aa2f7";
        purple = "#bb9af7";
        cyan = "#7dcfff";
        green = "#9ece6a";
        red = "#f7768e";
        fg = "#c0caf5";
        bg = "#1a1b26";
      };
    };
  };
}

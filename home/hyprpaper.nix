{ ... }:

{
  services.hyprpaper = {
    enable = true;
    settings = {
      splash = false;
      preload = [ "~/.config/hypr/background.webp" ];
      wallpaper = [ ",~/.config/hypr/background.webp" ];
    };
  };

  # Copy wallpaper
  home.file.".config/hypr/background.webp".source = ./hypr/background.webp;
}

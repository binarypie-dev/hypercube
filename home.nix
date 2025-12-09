{ config, pkgs, lib, inputs, username, ... }:

{
  imports = [
    ./home/packages.nix
    ./home/fish.nix
    ./home/neovim.nix
    ./home/git.nix
    ./home/wezterm.nix
    ./home/ghostty.nix
    ./home/hyprland.nix
    ./home/hypridle.nix
    ./home/hyprlock.nix
    ./home/hyprpaper.nix
    ./home/waybar.nix
    ./home/wofi.nix
    ./home/dunst.nix
    ./home/fzf.nix
    ./home/atuin.nix
    ./home/direnv.nix
    ./home/bat.nix
    ./home/zoxide.nix
    ./home/eza.nix
    ./home/starship.nix
    ./home/yazi.nix
    ./home/lazygit.nix
    ./home/k9s.nix
    ./home/bottom.nix
    ./home/readline.nix
    ./home/tmux.nix
    ./home/less.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.11";

  # Disable man page cache generation (fails in sandboxed builds)
  programs.man.generateCaches = false;

  # Disable xdg.portal in home-manager (handled at system level)
  xdg.portal.enable = lib.mkForce false;

  # Let home-manager manage itself
  programs.home-manager.enable = true;
}

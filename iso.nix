{ config, pkgs, lib, inputs, username, ... }:

{
  # Allow unfree packages (terraform)
  nixpkgs.config.allowUnfree = true;

  # Disable man cache generation (fails in sandboxed builds)
  documentation.man.generateCaches = false;

  imports = [
    # Base ISO modules
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares.nix"
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
  ];

  # ISO naming
  image.fileName = lib.mkForce "hypercube-${config.system.nixos.label}-x86_64.iso";
  isoImage = {
    volumeID = lib.mkForce "HYPERCUBE";
    makeEfiBootable = true;
    makeUsbBootable = true;
  };

  # Use our Hyprland config for the live session
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    xwayland.enable = true;
  };

  # Auto-login to live session (no greeter, straight to Hyprland)
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "Hyprland";
        user = "nixos";
      };
    };
  };

  # Live user setup
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.fish;
    initialHashedPassword = lib.mkForce null;
    initialPassword = "nixos";
  };

  programs.fish.enable = true;

  # Enable NetworkManager for easy wifi
  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false;

  # Audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Include all our packages in the live environment
  environment.systemPackages = with pkgs; [
    # Essentials
    git
    curl
    wget
    unzip
    neovim

    # Hyprland ecosystem
    waybar
    hyprpaper
    hyprpicker
    hypridle
    hyprlock
    hyprshot
    wl-clipboard
    wofi
    dunst
    libnotify

    # Terminals
    wezterm
    ghostty

    # File manager
    yazi

    # System tools
    btop
    ripgrep
    fd
    jq

    # Installer
    calamares
    calamares-nixos-extensions

    # For copying config after install
    rsync
  ];

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    noto-fonts
    noto-fonts-color-emoji
  ];

  # XDG portal (hyprland module adds the portal package automatically)
  xdg.portal = {
    enable = true;
    config.common.default = "*";
  };

  # Polkit
  security.polkit.enable = true;

  # Desktop entry for Calamares installer in wofi/app menu (backup if auto-start fails)
  xdg.mime.enable = true;
  environment.etc."xdg/applications/calamares.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Install NixOS
    Comment=Install NixOS to your computer
    Exec=sudo -E calamares
    Icon=calamares
    Terminal=false
    Categories=System;
  '';

  # Include the flake in the ISO for easy install
  environment.etc."hypercube-config" = {
    source = ./.;
    mode = "0755";
  };

  # Welcome message
  environment.etc."motd".text = ''

    ╔═══════════════════════════════════════════════════════════════╗
    ║                                                               ║
    ║   ██╗  ██╗██╗   ██╗██████╗ ███████╗██████╗  ██████╗██╗   ██╗ ║
    ║   ██║  ██║╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗██╔════╝██║   ██║ ║
    ║   ███████║ ╚████╔╝ ██████╔╝█████╗  ██████╔╝██║     ██║   ██║ ║
    ║   ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══╝  ██╔══██╗██║     ██║   ██║ ║
    ║   ██║  ██║   ██║   ██║     ███████╗██║  ██║╚██████╗╚██████╔╝ ║
    ║   ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝  ║
    ║                                                               ║
    ║   Cloud Native NixOS Workstation                              ║
    ║                                                               ║
    ║   Login: nixos / nixos                                        ║
    ║   Install: Run the Calamares installer from the menu          ║
    ║                                                               ║
    ║   Config location: /etc/hypercube-config                      ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝

  '';

  system.stateVersion = "25.11";
}

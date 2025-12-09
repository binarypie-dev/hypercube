{ config, pkgs, lib, inputs, username, ... }:

{
  # Allow unfree packages (terraform)
  nixpkgs.config.allowUnfree = true;

  imports = [
    # Base ISO modules
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares.nix"
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
  ];

  # ISO naming
  isoImage = {
    isoName = lib.mkForce "hypercube-${config.system.nixos.label}-x86_64.iso";
    volumeID = lib.mkForce "HYPERCUBE";
    makeEfiBootable = true;
    makeUsbBootable = true;
  };

  # Use our Hyprland config for the live session
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    xwayland.enable = true;
  };

  # Auto-login to live session
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
        user = "nixos";
      };
    };
  };

  # Live user setup
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.fish;
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
    noto-fonts-emoji
  ];

  # XDG portal
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Polkit
  security.polkit.enable = true;

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

{ config, pkgs, inputs, username, hostname, ... }:

{
  imports = [ ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = hostname;
  networking.networkmanager.enable = true;

  # Time zone and locale
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  # Nix settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # User account
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [ "networkmanager" "wheel" "docker" "libvirtd" ];
    shell = pkgs.fish;
  };

  # Enable fish system-wide
  programs.fish.enable = true;

  # Hyprland (from git for latest features)
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    xwayland.enable = true;
  };

  # Enable greetd for login
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  # Audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Docker for container workflows
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # Podman as alternative
  virtualisation.podman = {
    enable = true;
    dockerCompat = false; # Don't conflict with docker
  };

  # Libvirt for VMs
  virtualisation.libvirtd.enable = true;

  # System packages (user tools managed by home-manager)
  environment.systemPackages = with pkgs; [
    # Essential system utilities
    git
    curl
    wget
    unzip

    # Hyprland ecosystem (need system-level for greeter)
    hyprpicker
    hyprshot
    wl-clipboard
    cliphist
    swww
    libnotify

    # System
    polkit_gnome
    brightnessctl
    playerctl
    pavucontrol
    networkmanagerapplet
  ];

  # XDG portal (hyprland module adds the portal package automatically)
  xdg.portal = {
    enable = true;
    config.common.default = "*";
  };

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    noto-fonts
    noto-fonts-color-emoji
  ];

  # Polkit agent
  security.polkit.enable = true;
  systemd.user.services.polkit-gnome-agent = {
    description = "polkit-gnome-agent";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # OpenSSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Firewall
  networking.firewall.enable = true;

  system.stateVersion = "25.11";
}

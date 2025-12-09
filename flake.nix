{
  description = "Hypercube - NixOS Powered Cloud Native Workstation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";
  };

  outputs = { self, nixpkgs, home-manager, hyprland, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Define your username here
      username = "binarypie";
      hostname = "hypercube";
    in
    {
      # Full NixOS configuration
      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs username hostname; };
        modules = [
          /etc/nixos/hardware-configuration.nix
          ./configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs username; };
            home-manager.users.${username} = import ./home.nix;
          }
        ];
      };

      # Standalone home-manager for non-NixOS (Fedora, Ubuntu, etc.)
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit inputs username; };
        modules = [ ./home.nix ];
      };

      # Installable ISO image
      nixosConfigurations.iso = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs username hostname; };
        modules = [
          ./iso.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; username = "nixos"; };
            home-manager.users.nixos = import ./home.nix;
          }
        ];
      };

      # Build ISO with: nix build .#iso
      packages.${system}.iso = self.nixosConfigurations.iso.config.system.build.isoImage;

      # Development shell for working on this config
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nixfmt-classic
          nil
          statix
        ];
      };
    };
}

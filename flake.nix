{
  description = "A flake for NixOS system configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    warp-terminal-theme = {
      url = "github:Necryl/warp-terminal-theme";
      flake = false;
    };
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    cosmic-manager = {
      url = "github:HeitorAugustoLN/cosmic-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      warp-terminal-theme,
      zen-browser,
      cosmic-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      # Allow unfree packages in nixpkgs
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true; # Mirrors configuration.nix
      };
    in
    {
      # Define packages as a single attribute set
      packages.${system} = {
        hello = pkgs.hello;
        default = pkgs.hello;
      };

      # NixOS system configuration
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          # Import existing configurations
          ./default/hardware-configuration.nix
          ./default/configuration.nix
          ./packages.nix
          ./modules.nix
          ./cache.nix
          ./local/local-hardware.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.necryl = {
              imports = [
                ./home-manager/home.nix
                cosmic-manager.homeManagerModules.cosmic-manager
              ];
            };
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = {
              inherit
                inputs
                warp-terminal-theme
                self
                ;
            };
          }

          # Flake-specific settings
          {
            # Enable flake support (remove from configuration.nix to avoid duplication)
            nix.settings.experimental-features = [
              "nix-command"
              "flakes"
            ];
          }
        ];
      };
    };
}

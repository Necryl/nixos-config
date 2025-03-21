{
  description = "My NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvim-config = {
      url = "github:Necryl/nvim-config"; 
      flake = false; # repo isn’t a flake
    };
    warp-terminal-theme = {
      url = "github:Necryl/warp-terminal-theme";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, nvim-config, ... }:
  let
    system = "x86_64-linux"; # Adjust if you're on a different architecture (e.g., "aarch64-linux")
  in {
    nixosConfigurations.mySystem = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.necryl = import ./home.nix;
	        home-manager.extraSpecialArgs = { inherit nvim-config;};
        }
      ];
    };
  };
}

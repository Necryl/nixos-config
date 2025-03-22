{
  description = "My NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    warp-terminal-theme = {
      url = "github:Necryl/warp-terminal-theme";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, warp-terminal-theme, ... }:
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
          home-manager.users.necryl = import home-manager/home.nix;
	        home-manager.extraSpecialArgs = { inherit warp-terminal-theme;};
        }
      ];
    };
  };
}

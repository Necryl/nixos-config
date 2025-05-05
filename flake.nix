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
    future-cursors = {
      url = "github:yeyushengfan258/Future-cursors";
      flake = false; # This is a non-flake repository
    };
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      warp-terminal-theme,
      zen-browser,
      future-cursors,
      ...
    }@inputs:
    let
      system = "x86_64-linux"; # Adjust if you're on a different architecture (e.g., "aarch64-linux")
      pkgs = import nixpkgs { inherit system; };
      futureCursors = pkgs.stdenv.mkDerivation {
        pname = "future-cursors";
        version = "0.1"; # Arbitrary version, as the repo doesn't specify
        src = future-cursors;

        nativeBuildInputs = with pkgs; [
          inkscape
          xorg.xcursorgen
        ];
        buildInputs = with pkgs; [ python3 ];

        buildPhase = ''
          # Build the cursor theme as per the repository's instructions
          bash ./build.sh
        '';

        installPhase = ''
          mkdir -p $out/share/icons/Future-cursors
          cp -r ./dist/* $out/share/icons/Future-cursors/
        '';
      };
    in
    {
      nixosConfigurations.mySystem = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          {
            environment.systemPackages = [ futureCursors ];
            # Optional: Set the cursor theme system-wide
            environment.etc."xdg/gtk-3.0/settings.ini".text = ''
              [Settings]
              gtk-cursor-theme-name=Future-cursors
            '';
          }
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.necryl = import home-manager/home.nix;
            home-manager.extraSpecialArgs = { inherit inputs warp-terminal-theme; };
          }
        ];
      };
    };
}

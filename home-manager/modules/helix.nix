{ config, pkgs, ... }:

{
  programs.helix = {
    enable = true;
    package = pkgs.helix; # Use the Helix from nixpkgs

    # Theme configuration
    settings = {
      theme = "tokyo-night-transparent"; # Built-in Tokyo Night theme
    };

    # Optional: Override theme for transparency
    themes = {
      tokyo-night-transparent = {
        inherits = "tokyonight";
        "ui.background" = { bg = "none"; }; # Transparent background
      };
    };
  };

  # Helix dependencies (e.g., LSPs if needed)
  home.packages = with pkgs; [
    # Add more tools here (e.g., rust-analyzer)
  ];
}

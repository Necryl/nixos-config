{
  config,
  pkgs,
  lib,
  ...
}:

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
        "ui.background" = {
          bg = "none";
        }; # Transparent background
        "ui.text" = {
          bg = "none";
        }; # Text background
      };
    };

    languages.language = [
      {
        name = "nix";
        auto-format = true;
        formatter.command = lib.getExe pkgs.nixfmt-rfc-style;
      }
    ];

  };

  # Helix dependencies (e.g., LSPs if needed)
  home.packages = with pkgs; [
    # Add more tools here (e.g., rust-analyzer)
  ];
}

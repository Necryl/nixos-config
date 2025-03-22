{ config, pkgs, ... }:

{
  programs.helix = {
    enable = true;
    package = pkgs.helix; # Use the Helix from nixpkgs

    # Theme configuration
    settings = {
      theme = "tokyo-night"; # Built-in Tokyo Night theme
      editor = {
        color-modes = true; # Enable true color support
        cursorline = true; # Highlight the current line
        bufferline = "multiple"; # Show all open buffers
      };
    };

    # Optional: Override theme for transparency
    themes = {
      tokyo-night-transparent = {
        inherits = "tokyonight";
        "ui.background" = { bg = "none"; }; # Transparent background
      };
    };
  };

  # Force runtime link directly from package
  home.file.".config/helix/runtime" = {
    source = "${pkgs.helix}/share/helix/runtime";
    recursive = true; # Ensure all subdirs (like themes) are linked
  };

  # Helix dependencies (e.g., LSPs if needed)
  home.packages = with pkgs; [
    # Add more tools here (e.g., rust-analyzer)
  ];
}

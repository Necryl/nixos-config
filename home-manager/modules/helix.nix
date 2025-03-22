{ config, pkgs, ... }:

{
  programs.helix = {
    enable = true;
    package = pkgs.helix; # Use the Helix from nixpkgs
  };

  # Add Helix dependencies
  home.packages = with pkgs; [
    # Add more tools here if needed (e.g., rust-analyzer)
  ];
}

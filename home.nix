{ config, pkgs, ... }:
{
  home.username = "necryl"; # Replace with your username
  home.homeDirectory = "/home/necryl";
  home.stateVersion = "23.11"; # Adjust based on your NixOS version (e.g., "24.05" if newer)

  # Example: Install some packages
  home.packages = with pkgs; [
    firefox
    neovim
    warp-terminal
    gh
  ];

  # Example: Enable a program (e.g., Git)
  programs.git = {
    enable = true;
    userName = "necryl";
    userEmail = "your.email@example.com";
  };
}

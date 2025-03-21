{ config, pkgs, nvim-config, ... }:
{
  home.username = "necryl"; # Replace with your username
  home.homeDirectory = "/home/necryl";
  home.stateVersion = "23.11"; # Adjust based on your NixOS version (e.g., "24.05" if newer)

  # Example: Install some packages
  home.packages = with pkgs; [
    firefox
    neovim
    ripgrep
    warp-terminal
    gh
    gcc
  ];

  # Example: Enable a program (e.g., Git)
  programs.git = {
    enable = true;
    userName = "Necryl";
    userEmail = "74096664+Necryl@users.noreply.github.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
  programs.ssh = {
  enable = true;
  extraConfig = ''
    Host github.com
      HostName github.com
      User git
      IdentityFile ~/.ssh/id_ed25519
  '';
};
home.sessionVariables = {
TERMINAL = "warp-terminal";
};
home.file.".config/nvim".source = nvim-config; # Nix pulls this from GitHub

}

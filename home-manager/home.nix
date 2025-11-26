{
  self,
  config,
  pkgs,
  inputs,
  warp-terminal-theme,
  antigravity,
  ...
}:
{
  imports = [
    ./modules/helix.nix
    ./modules/btop.nix
    ./modules/de.nix
    ./modules/warp-terminal.nix
    ./modules/git.nix
    ./modules/yazi.nix
    ./modules/xdg.nix
    ./modules/foot.nix
    ./modules/rust.nix
  ];
  home.stateVersion = "24.11"; # Adjust based on your NixOS version (e.g., "24.05" if newer)

  # Example: Install some packages
  home.packages = with pkgs; [
    imagemagick # Provides 'magick'/'convert'
    obsidian
    ueberzugpp # image rednering support for yazi
    nodejs
    emmet-language-server
    nodePackages.pnpm
    nodePackages.prettier
    inkscape
    microsoft-edge
    discord-canary
    dupeguru
    krita
    vscode
    gimp3-with-plugins
    tmux
    gemini-cli

    gcc
    google-chrome
    ungoogled-chromium
    anydesk
    antigravity.packages.x86_64-linux.default
  ];

  # programs.kitty.enable = true; # required for the default Hyprland config

  # Example: Enable a program (e.g., Git)
  programs.bash = {
    enable = true;
    shellAliases = {
      new = "touch";
    };
  };

  programs.ssh = {
    enableDefaultConfig = false;
    matchBlocks."*" = {
      addKeysToAgent = "yes";
    };
  };

  programs.tmux = {
    enable = true;
    extraConfig = ''
      set -g mouse on
      set -g default-terminal "xterm-256color"
      set -as terminal-overrides ",xterm-256color:Tc"
      set -g default-command ${pkgs.fish}/bin/fish
    '';
  };

  programs.fish = {
    enable = true;
    shellAliases = {
      new = "touch";
    };
  };

  home.sessionVariables = {
    TERMINAL = "foot";
  };

}

{
  self,
  config,
  pkgs,
  inputs,
  warp-terminal-theme,
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
  ];
  home.username = "necryl"; # Replace with your username
  home.homeDirectory = "/home/necryl";
  home.stateVersion = "24.11"; # Adjust based on your NixOS version (e.g., "24.05" if newer)

  # Example: Install some packages
  home.packages = with pkgs; [
    imagemagick # Provides 'magick'/'convert'
    obsidian
    ueberzugpp # image rednering support for yazi
    nodejs
    nodePackages.svelte-language-server # Svelte LSP
    nodePackages.typescript-language-server # JS and TS LSP
    nodePackages.vscode-langservers-extracted # JSON LSP
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
    code-cursor
    tmux
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

  home.sessionVariables = {
    TERMINAL = "warp-terminal";
    # NIXOS_OZONE_WL = "1";
    # PATH = "$HOME/.local/bin:$PATH";
  };

  # xdg.mimeApps = {
  #   enable = true;
  #   defaultApplications = {
  #     "application/vnd.oasis.opendocument.spreadsheet" = "org.gnumeric.gnumeric.desktop";
  #     "application/vnd.ms-excel" = "org.gnumeric.gnumeric.desktop";
  #     "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" =
  #       "org.gnumeric.gnumeric.desktop";
  #     "text/csv" = "org.gnumeric.gnumeric.desktop";
  #   };
  # };

}

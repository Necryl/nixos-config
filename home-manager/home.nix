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
    ./modules/de.nix
  ];
  home.username = "necryl"; # Replace with your username
  home.homeDirectory = "/home/necryl";
  home.stateVersion = "24.11"; # Adjust based on your NixOS version (e.g., "24.05" if newer)

  # Example: Install some packages
  home.packages = with pkgs; [
    firefox
    warp-terminal
    gh
    fd
    fzf
    imagemagick # Provides 'magick'/'convert'
    nodejs
    inputs.zen-browser.packages."${system}".default
    persepolis
    nodePackages.npm
    nodePackages.svelte-language-server # Svelte LSP
    nodePackages.typescript-language-server # JS and TS LSP
    nodePackages.vscode-langservers-extracted # JSON LSP
    emmet-language-server
    nodePackages.pnpm
    nodePackages.prettier
    obsidian
    mission-center
    discord
    wl-clipboard
    ueberzugpp # image rednering support for yazi
    brave
    nautilus
    gnome-tweaks
    libnotify
  ];

  programs.kitty.enable = true; # required for the default Hyprland config

  # Manage btop configuration
  programs.btop = {
    enable = true; # Enables Home Manager to manage btop
    settings = {
      color_theme = "adapta"; # Sets the theme to Adapta
      theme_background = false; # Disables the theme background
    };
  };

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
  programs.bash = {
    enable = true;
    shellAliases = {
      new = "touch";
    };
  };
  home.sessionVariables = {
    TERMINAL = "warp-terminal";
    NIXOS_OZONE_WL = "1";
    PATH = "$HOME/.local/bin:$PATH";
  };

  home.file.".local/bin/onedrive.sh" = {
    source = "${self}/Utility Scripts/onedrive.sh"; # Copy onedrive.sh from Utility Scripts/
    executable = true; # Make the script executable
  };
  home.file.".local/share/warp-terminal/themes/".source = warp-terminal-theme;

  # Create the .desktop file for GNOME
  xdg.desktopEntries.onedrive = {
    name = "OneDrive Toggle";
    comment = "Toggle OneDrive on or off";
    exec = "${pkgs.bash}/bin/bash /home/necryl/.local/bin/onedrive.sh"; # Update to user-writable path
    terminal = false;
    type = "Application";
    icon = "onedrive";
    categories = [ "Utility" ];
  };

}

{
  config,
  pkgs,
  inputs,
  warp-terminal-theme,
  ...
}:
let
  # Define the path to your onedrive.sh script
  onedriveScript = "${config.home.homeDirectory}/nixos-config/Utility Scripts/onedrive.sh";
in

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
    (pkgs.writeTextFile {
      name = "onedrive.sh";
      executable = true;
      destination = "/bin/onedrive.sh"; # Place in a system-wide bin for accessibility
      text = builtins.readFile onedriveScript; # Read the script content
    })
  ];

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
  };
  home.file.".local/share/warp-terminal/themes/".source = warp-terminal-theme;

  # Create the .desktop file for GNOME
  xdg.desktopEntries.onedrive = {
    name = "OneDrive Toggle";
    comment = "Toggle OneDrive on or off";
    exec = "${pkgs.bash}/bin/bash /bin/onedrive.sh";
    terminal = false;
    type = "Application";
    icon = "onedrive";
    categories = [ "Utility" ];

  };

}

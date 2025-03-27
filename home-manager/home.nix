{
  config,
  pkgs,
  inputs,
  warp-terminal-theme,
  ...
}:
{
  imports = [
    ./modules/helix.nix
  ];
  home.username = "necryl"; # Replace with your username
  home.homeDirectory = "/home/necryl";
  home.stateVersion = "23.11"; # Adjust based on your NixOS version (e.g., "24.05" if newer)

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
  home.sessionVariables = {
    TERMINAL = "warp-terminal";
  };
  home.file.".local/share/warp-terminal/themes/".source = warp-terminal-theme;

}

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
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = pkgs.hyprland;
    settings = {
      "$mod" = "SUPER";
      bind = [
        "$mod, T, exec, warp-terminal"
        "ALT, F4, killactive"
        "$mod, M, exit"
        "$mod, E, exec, dolphin"
        "$mod, W, exec, zen"
        "$mod, SPACE, exec, rofi -show drun"
        "$mod, Q, togglefloating"
      ];
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
      };
      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, myBezier, popin 80%"
          "border, 1, 10, default"
          "fade, 1, 7, myBezier"
        ];
      };
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0;
      };
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
      };
      exec-once = [
        "swww init && swww img /home/necryl/wallpaper.jpg"
        "waybar"
        "dunst"
      ];
    };
  };

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [
          "tray"
          "battery"
        ];
      };
    };
  };
}

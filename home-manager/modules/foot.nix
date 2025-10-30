{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.foot = {
    enable = true;
    server.enable = false;

    settings = {
      main = {
        font = "Fira Code:size=11";
        pad = "10x10";
        shellProgram = [
          "tmux"
          "-u"
        ];
      };
      colors = {
        alpha = 0.8;

        # Foreground (text) color
        foreground = "80c0ff";

        # Background color (using the darkest shade from Warp)
        background = "00081e";

        # Terminal colors (ANSI colors)
        # Normal colors (0-7)
        regular0 = "3e7bdc"; # Black
        regular1 = "ff8c35"; # Red
        regular2 = "38ffc9"; # Green
        regular3 = "7208f4"; # Yellow
        regular4 = "ec8129"; # Blue
        regular5 = "ffdb1a"; # Magenta
        regular6 = "2ba5ff"; # Cyan
        regular7 = "d2dbe8"; # White

        # Bright colors (0-7)
        bright0 = "3e7bdc"; # Bright Black
        bright1 = "ff7200"; # Bright Red
        bright2 = "00fdbb"; # Bright Green
        bright3 = "7300ff"; # Bright Yellow
        bright4 = "ec8129"; # Bright Blue
        bright5 = "fdd600"; # Bright Magenta
        bright6 = "5db6ff"; # Bright Cyan
        bright7 = "e9f2ff"; # Bright White

        # Cursor color (using Warp's accent color)
        cursor = "4136d9 80c0ff";

      };
    };

  };
}

{ config, pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = pkgs.hyprland;
    settings = {
      "$mod" = "SUPER";
      bind = [
        "$mod, T, exec, warp-terminal"
        "ALT, F4, killactive"
        "$mod, P, exit"
        "$mod, E, exec, dolphin"
        "$mod, W, exec, zen"
        "$mod, SPACE, exec, rofi -show drun"
        "$mod, Q, togglefloating"
        "$mod, F, fullscreen"
        "$mod, M, fullscreen, 1"
        # Workspace switching
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        # Move windows to workspaces
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        # Scroll through workspaces
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"
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

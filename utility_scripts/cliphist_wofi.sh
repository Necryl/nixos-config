# bash "/home/necryl/nixos-config/utility_scripts/cliphist_wofi.sh"
cliphist list | wofi --dmenu --prompt "Clipboard:" --insensitive | cliphist decode | wl-copy

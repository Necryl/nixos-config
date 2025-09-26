# bash "/home/necryl/nixos-config/utility_scripts/cliphist_wofi.sh"
cliphist list | head -n 15 | wofi --dmenu --prompt "Clipboard:" --insensitive --cache-file /dev/null --pre-display-cmd "echo '%s' | cut -f 2- | tr -d '\n'" | cliphist decode | wl-copy

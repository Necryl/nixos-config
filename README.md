# My NixOS Setup

This repository contains my personal NixOS configuration. It's a highly customized setup with a focus on a cyberpunk aesthetic and a terminal-centric workflow.

## Key Features

*   **Desktop Environment:** [COSMIC DE](https://github.com/pop-os/cosmic-epoch)
*   **Terminal:** [foot](https://codeberg.org/dnkl/foot) (primary), with [Warp](https://www.warp.dev/) as a fallback.
*   **Editor:** [Helix](https://helix-editor.com/), with extensive language server configuration for web development.
*   **Theme:** A custom cyberpunk theme, including a GRUB theme, a Cosmic DE theme, and a terminal color scheme.
*   **Workflow:** A terminal-centric workflow with `tmux` and a variety of command-line tools.
*   **Compatibility:** A wide range of compatibility tools, including `wine`, `distrobox`, `nix-alien`, `steam-run`, and `appimage-run`.

## Workflow

The system is managed using a custom `update.sh` script, which automates the process of updating the system, including pulling from a Git remote, updating flake inputs, and rebuilding the system.

To update the system, run:

```bash
./update.sh
```

## Machine-specific Configuration

This configuration uses a file named `local/local-hardware.nix` for machine-specific hardware configuration. This file is not tracked by Git.

To use this configuration on your own machine, you will need to:

1.  **Create your own `local-hardware.nix` file.** You can use the `local/local-hardware-template.nix.sample` as a starting point.
2.  **Configure it for your hardware.** You can use the `nixos-generate-config` command to generate a hardware configuration for your system.
3.  **Edit the path in `flake.nix`** to point to the location of your `local/local-hardware.nix` file.

Look for this line in `flake.nix`:

```nix
/home/necryl/nixos-config/local/local-hardware.nix
```

And change it to the correct path for your system.

This setup requires the use of the `--impure` flag when running `nixos-rebuild`.

## Themes

*   **Cosmic DE Theme:** The theme for Cosmic DE is defined in `CosmicCyberpunkDarkTheme.ron`. This theme needs to be manually imported in the Cosmic DE settings.
*   **Cursor Theme:** The `WinSur-white-cursors` directory contains a cursor theme. This theme is not yet implemented in the configuration.
# NixOS Configuration

## Project Overview

This repository contains a comprehensive and personalized NixOS configuration managed using Nix Flakes. It is designed to provide a consistent, reproducible, and highly customized desktop environment with a focus on a cyberpunk aesthetic and a terminal-centric workflow.

The configuration is modular, separating system-wide settings, user-specific environments, and package definitions.

**Key Technologies:**
*   **System:** NixOS
*   **Configuration Management:** Nix Flakes, Home-Manager
*   **Desktop Environment:** Cosmic DE
*   **Terminal:** foot, Warp
*   **Editor:** Helix

## Building and Running

The primary method for managing and applying this configuration is through the `update.sh` script. This script automates the entire process of updating, building, and deploying the system configuration.

**Automated Update and Rebuild:**

The `update.sh` script provides an interactive and automated way to manage the system. It handles:
*   Checking for local and remote Git changes.
*   Updating flake inputs.
*   Detecting configuration changes to avoid unnecessary rebuilds.
*   Prompting for a rebuild strategy (`switch` for immediate activation, `boot` for activation on next reboot).
*   Committing and pushing changes.

To run the script:
```bash
./update.sh
```

**Manual Rebuild:**

If you need to manually rebuild the system, you can use the standard NixOS command. The hostname for the primary configuration is `nixos`.

```bash
# To activate the new configuration immediately
sudo nixos-rebuild switch --flake .#nixos --impure

# To activate the new configuration on the next boot (safer)
sudo nixos-rebuild boot --flake .#nixos --impure
```
**Note:** The `--impure` flag is required because this configuration loads a machine-specific, untracked hardware profile from `/home/necryl/nixos-config/local/local-hardware.nix` as noted in the `README.md`.

## Development Conventions

*   **Structure:** The configuration is highly modularized.
    *   `flake.nix`: The central entry point that defines inputs and ties all modules together.
    *   `default/configuration.nix`: Contains base system-wide settings (bootloader, networking, users, etc.).
    *   `home-manager/`: Contains user-specific configurations managed by Home-Manager.
        *   `home-manager/home.nix`: A common base for all users.
        *   `home-manager/modules/`: Individual application configurations (e.g., `helix.nix`, `git.nix`).
        *   `home-manager/users/`: User-specific overrides and imports (e.g., `necryl.nix`).
    *   `packages.nix`: Defines additional system packages.
*   **Users:** The configuration is set up for two users, `necryl` and `work`, with shared settings in `home.nix` and specific settings in their respective files under `home-manager/users/`.
*   **Hardware Specificity:** Machine-specific hardware settings are intentionally kept separate in an untracked file (`local/local-hardware.nix`) to maintain portability of the main configuration. This is a common and effective pattern in NixOS community projects.
*   **Updates:** All updates, including package and flake updates, should be managed through the `update.sh` script to ensure consistency and proper state tracking.

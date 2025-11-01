{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.helix = {
    enable = true;
    package = pkgs.helix; # Use the Helix from nixpkgs

    # Theme configuration
    settings = {
      theme = "tokyo-night-transparent"; # Built-in Tokyo Night theme
      editor = {
        soft-wrap.enable = true;
        end-of-line-diagnostics = "hint";

        inline-diagnostics.cursor-line = "warning";
        color-modes = true;
        auto-format = true;
        cursorline = true;
        cursorcolumn = true;
        indent-guides.render = true;
        cursor-shape = {
          normal = "block";
          insert = "bar";
          select = "underline";
        };
      };
      keys.normal = {
        "C-s" = ":w";

        "C-q" = ":q";

        " " = {
          q = ":q";
          Q = ":qa";
        };

        # Alt+Up or Alt+j to move line up
        "A-up" = [
          "extend_to_line_bounds"
          "delete_selection"
          "move_line_up"
          "paste_before"
        ];
        "A-j" = [
          "extend_to_line_bounds"
          "delete_selection"
          "move_line_up"
          "paste_before"
        ];

        # Alt+Down or Alt+k to move line down
        "A-down" = [
          "extend_to_line_bounds"
          "delete_selection"
          "paste_after"
        ];
        "A-k" = [
          "extend_to_line_bounds"
          "delete_selection"
          "paste_after"
        ];
      };

      keys.insert = {
        C-s = ":w";
      };

      keys.select = {
        C-s = ":w";

        # Alt+Up or Alt+j to move selected lines up
        "A-up" = [
          "extend_to_line_bounds"
          "delete_selection"
          "move_line_up"
          "paste_before"
        ];
        "A-j" = [
          "extend_to_line_bounds"
          "delete_selection"
          "move_line_up"
          "paste_before"
        ];

        # Alt+Down or Alt+k to move selected lines down
        "A-down" = [
          "extend_to_line_bounds"
          "delete_selection"
          "paste_after"
        ];
        "A-k" = [
          "extend_to_line_bounds"
          "delete_selection"
          "paste_after"
        ];
      };
    };
    # test
    # Optional: Override theme for transparency
    themes = {
      tokyo-night-transparent = {
        inherits = "tokyonight";
        "ui.background" = {
          bg = "none";
        }; # Transparent background
        "ui.text" = {
          bg = "none";
        }; # Text background
      };
    };

    languages = {
      language = [
        {
          name = "nix";
          auto-format = true;
          formatter.command = lib.getExe pkgs.nixfmt-rfc-style;
        }
        {
          name = "svelte";
          auto-format = true;
          language-servers = [ "svelteserver" ];
        }
        {
          name = "javascript";
          auto-format = true;
          formatter = {
            args = [
              "--parser"
              "javascript"
            ];
            command = lib.getExe pkgs.nodePackages.prettier;
          };
          language-servers = [ "typescript-language-server" ];
        }
        {
          name = "typescript";
          auto-format = true;
          formatter = {
            args = [
              "--parser"
              "typescript"
            ];
            command = lib.getExe pkgs.nodePackages.prettier;
          };
          language-servers = [ "typescript-language-server" ];
        }
        {
          name = "json";
          auto-format = true;
          language-servers = [ "vscode-json-language-server" ];
        }
        {
          name = "html";
          auto-format = true;
          formatter = {
            command = lib.getExe pkgs.nodePackages.prettier;
            args = [
              "--parser"
              "html"
            ];
          };
          language-servers = [
            "vscode-html-language-server"
            "emmet-lsp"
          ]; # Use both for maximum coverage
        }
        {
          name = "astro";
          auto-format = true;
          formatter = {
            command = lib.getExe pkgs.nodePackages.prettier;
            args = [
              "--plugin=prettier-plugin-astro"
              "--parser=astro"
            ];
          };
          language-servers = [ "astro-ls" ];
        }
      ];
      language-server = {
        svelteserver = {
          command = lib.getExe pkgs.nodePackages.svelte-language-server;
          args = [ "--stdio" ];
        };
        typescript-language-server = {
          command = lib.getExe pkgs.nodePackages.typescript-language-server;
          args = [ "--stdio" ];
        };
        vscode-json-language-server = {
          command = "${pkgs.nodePackages.vscode-langservers-extracted}/bin/vscode-json-language-server";
          args = [ "--stdio" ];
        };
        emmet-lsp = {
          command = lib.getExe pkgs.emmet-language-server;
          args = [ "--stdio" ];
        };
        astro-ls = {
          command = lib.getExe pkgs.astro-language-server;
          args = [ "--stdio" ];
        };

      };
    };
  };

  # Helix dependencies (e.g., LSPs if needed)
  home.packages = with pkgs; [
    nodePackages.svelte-language-server # Svelte LSP
    nodePackages.typescript-language-server # JS and TS LSP
    nodePackages.vscode-langservers-extracted # JSON LSP
  ];
}

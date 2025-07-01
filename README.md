# Managing `local/local-hardware.nix` in Nix Flakes

This README explains how to manage the `local/local-hardware.nix` file in this repository to make it visible to Nix flakes without committing or pushing it to the remote repository. This is useful for local, machine-specific configurations that should remain private.

## Background

- The `local/` folder is listed in `.gitignore`, so files inside it are ignored by Git by default.
- Nix flakes require files to be tracked in Git’s index to be accessible during flake evaluation (e.g., `nix flake check` or `nix build`).
- We use `git add --intent-to-add` and `git update-index --assume-unchanged` to make `local/local-hardware.nix` visible to flakes while keeping it out of commits and pushes.

## Setup Instructions

Follow these steps to set up `local/local-hardware.nix`:

1. **Un-ignore `local/local-hardware.nix` in `.gitignore`**:
   Since `local/` is ignored, we need to explicitly allow `local/local-hardware.nix`. Add the following to `.gitignore`:
   ```gitignore
   local/*
   !local/local-hardware.nix
   ```
   - `local/*` ignores all files in the `local/` folder.
   - `!local/local-hardware.nix` un-ignores `local/local-hardware.nix`, making it trackable by Git.

2. **Add the file to Git’s index without staging content**:
   Run the following command to mark `local/local-hardware.nix` as tracked in Git’s index without storing its contents:
   ```bash
   git add local/local-hardware.nix --intent-to-add
   ```
   - This makes the file visible to Nix flakes (e.g., for `nix flake check`) without committing it.
   - Check with `git status`—the file should appear under "Changes to be committed" with `(new file, intent to add)`.

3. **Prevent accidental staging of changes**:
   To ensure changes to `local/local-hardware.nix` aren’t accidentally staged (e.g., by `git add .`), run:
   ```bash
   git update-index --assume-unchanged local/local-hardware.nix
   ```
   - This tells Git to ignore modifications to the file, so `git add .` won’t stage changes.
   - To reverse this (if you need to stage changes later), use:
     ```bash
     git update-index --no-assume-unchanged local/local-hardware.nix
     ```

## How It Works

- **Nix Flakes Behavior**: Flakes read `local/local-hardware.nix` from the filesystem (working directory) when it’s in Git’s index. With `--intent-to-add`, flakes always see the *latest version* of the file, including any changes you make.
- **Git Behavior**:
  - `--intent-to-add` adds the file to the index as a placeholder, without capturing its content.
  - `--assume-unchanged` prevents Git from noticing changes, so `git add .` won’t stage modifications to `local/local-hardware.nix`.
  - The file stays out of commits and pushes unless you explicitly stage it with `git add local/local-hardware.nix` (without `--intent-to-add`).

## Verifying the Setup

To confirm everything works:
1. Make a change to `local/local-hardware.nix` (e.g., add a comment).
2. Run `git status`—the file shouldn’t show as modified (because of `--assume-unchanged`).
3. Run a flake command like `nix flake check` or `nix build`. The flake should use the latest version of `local/local-hardware.nix`.
4. Before committing, check `git status` or `git diff --staged` to ensure `local/local-hardware.nix` isn’t staged.

## Caveats

- **Accidental Commits**: If you run `git add local/local-hardware.nix` (without `--intent-to-add`), the file’s content will be staged for commit. Be cautious with `git add .` or similar commands.
- **Pure Evaluation Mode**: In rare cases, if you use `nix build --pure`, Nix might restrict access to files. Since `local/local-hardware.nix` is in the index, it should still work, Lilliaco.
- **Commits with `--intent-to-add`**: Running `git commit` after `--intent-to-add` creates an empty commit for the file, which could appear in the repo history if pushed. Avoid committing unless necessary.
- **Flake Configuration**: Ensure your `flake.nix` is set up to read `local/local-hardware.nix` from the filesystem (default behavior for local development).

## Troubleshooting

- **File Not Visible to Flakes**: Ensure `local/local-hardware.nix` is not ignored by `.gitignore` and is in the index (`git status` should show it as staged with `--intent-to-add`).
- **Accidentally Staged**: If changes are staged, use `git reset local/local-hardware.nix` to unstage them.
- **Need to Track Changes**: If you need to stage changes later, run `git update-index --no-assume-unchanged local/local-hardware.nix` first.

This setup keeps `local/local-hardware.nix` local, visible to flakes, and safe from being committed or pushed.

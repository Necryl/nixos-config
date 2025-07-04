# My nixos setup

It is a simple  setup with Cosmic DE, Helix as the code editor, Warp as the terminal. And a bunch of other random softwares I needed. I will try to build the system up to be as polished as it can be. The packages in the home.nix is more just personal softwares, not really necessary for the system. Although some of the customising of some softwares like helic and yazi is done through home-manager.

I aim for a cyberpunk aesthetic as that's what I love. It is not completely there yet, but we will see.
There is a cosmic theme file in the main directory, that has to be imported in COsmic Appearance settings to get the color scheme.

> # Managing `local/local-hardware.nix` in Nix Flakes

 The local-hardware.nix will be unique for each machine. So do not push that file to the repo.

For now I will use a absolute path to it and use --impure to build the system. But if you wanna see a relative path be sure not to commit it or push it to the repo.
 However if you don't add it to git, then flakes won't be able to see it. So currently the best worst solution I have is to remove it from .gitignore just before rebuilding, add it to git, rebuild the system and then add it to .gitignore again, remove the file from git cache and continue. Basically just ensure the file is not added to any commit or pushed to the repo.
The I wish there was a better solution.

If you decided to go with the absolute path, make sure you edit the absolute path to match your location of the files.

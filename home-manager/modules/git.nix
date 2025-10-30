{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Necryl";
        email = "74096664+Necryl@users.noreply.github.com";
      };
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

}

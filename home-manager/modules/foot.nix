{
  config,
  pkgs,
  lib,
  ...
}:

let
  foot-theme = pkgs.fetchurl {
    url = "https://codeberg.org/dnkl/foot/raw/branch/master/themes/tokyonight-night";
    hash = "sha256-V0m8tmR4QFRWe//ltX++ojD5X+x2x3cRHaKWfnL8OH8=";
  };
in
{
  programs.foot = {
    enable = true;
    server.enable = false;

    settings = {
      main = {
        # font = "JetBrainsMonoNFM-Regular:size=14";
        include = "${foot-theme}";
      };
      colors.alpha = 0.5;
    };

  };
}

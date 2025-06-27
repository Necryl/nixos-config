{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Yazi config
  programs.yazi = {
    enable = true;
    settings = {
    };
  };

  home.file.".config/yazi/theme.toml".text = ''
    [flavor]
    use = "tokyo-night"
    dark = "tokyo-night"
  '';

  # Clone the entire tokyo-night.yazi repo into flavors/
  home.file.".config/yazi/flavors/tokyo-night.yazi".source = pkgs.fetchFromGitHub {
    owner = "BennyOe";
    repo = "tokyo-night.yazi";
    rev = "main"; # Use 'main' branch
    sha256 = "sha256-WtOjzk7ATA4Ue6Lu6IgiweOIHk/BK01Khio6ESF201k="; # Update if needed
  };

  # Helix dependencies (e.g., LSPs if needed)
  home.packages = with pkgs; [
    # Add more tools here (e.g., rust-analyzer)
  ];
}

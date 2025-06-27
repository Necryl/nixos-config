{
  config,
  pkgs,
  inputs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    helix
    warp-terminal
    appimage-run
    steam-run
    gh
    git
    gnumeric
    rclone
    tree
    libnotify
    vlc
    inputs.zen-browser.packages."${system}".default
    nodejs
    nodePackages.npm
    fd
    fzf
    mission-center
    wl-clipboard
    btop
    yazi
    neofetch
    (adi1090x-plymouth-themes.override { selected_themes = [ "spinner_alt" ]; })
    pciutils
    usbutils
    wineWowPackages.stable
    nomacs
    libreoffice
    foot
    gparted
    xdg-desktop-portal
    xdg-desktop-portal-cosmic
    cosmic-ext-tweaks
    cosmic-ext-calculator
    cosmic-wallpapers
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    font-awesome
    google-fonts
  ];

}

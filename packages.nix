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
    # gnumeric
    rclone
    tree
    libnotify
    vlc
    inputs.zen-browser.packages."${system}".default
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
    wineWowPackages.waylandFull
    nomacs
    libreoffice
    foot
    gparted
    cosmic-ext-calculator
    distrobox
    p7zip-rar
    efibootmgr
    inputs.nix-alien.packages.${pkgs.system}.default

    kdePackages.dolphin
    kdePackages.dolphin-plugins
    kdePackages.ark
    kdePackages.konsole
    kdePackages.kio-fuse # to mount remote filesystems via FUSE
    kdePackages.kio-extras # extra protocols support (sftp, fish and more)
    kdePackages.qtsvg
    kdePackages.audiocd-kio
    kdePackages.baloo
    kdePackages.kio-admin
    kdePackages.kio-gdrive
    kdePackages.kompare
    kdePackages.ffmpegthumbs
    icoutils
    kdePackages.kdegraphics-thumbnailers
    kdePackages.kimageformats
    libappimage
    resvg
    kdePackages.taglib
    kdePackages.kservice
    kdePackages.qt6ct
    kdePackages.qtstyleplugin-kvantum
    kdePackages.breeze-icons
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    font-awesome
    google-fonts
  ];

}

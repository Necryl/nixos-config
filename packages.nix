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
    (writeTextFile {
      name = "zen-browser-desktop";
      destination = "/share/applications/zen-browser.desktop";
      text = ''
        [Desktop Entry]
        Name=Zen Browser
        Exec=${inputs.zen-browser.packages."${system}".default}/bin/zen %U
        Type=Application
        Terminal=false
        Categories=Network;WebBrowser;
        MimeType=text/html;x-scheme-handler/http;x-scheme-handler/https;
      '';
    })

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
    cosmic-ext-calculator
    distrobox
    p7zip-rar
    efibootmgr

    kdePackages.dolphin
    kdePackages.dolphin-plugins
    kdePackages.ark
    kdePackages.konsole
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    font-awesome
    google-fonts
  ];

}

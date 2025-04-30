# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

let
  cybergrub-theme = pkgs.fetchFromGitHub {
    owner = "adnksharp";
    repo = "CyberGRUB-2077";
    rev = "76b13c8e591958a104f6186efae3000da1032a35"; # Use a specific commit hash for reproducibility (check the latest commit on GitHub)
    sha256 = "sha256-Y5Jr+huIXnsSbN/HFhXQewFprX+FySTPdUa1KT0nMfM="; # Replace with actual hash
  };
in
{
  imports = [
    # Include the results of the hardware scan.
    /etc/nixos/hardware-configuration.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    device = "nodev"; # For UEFI, set to "nodev" instead of a disk
    efiSupport = true;
    useOSProber = true; # Optional: Detect other operating systems

    # Flexible resolution detection for both UEFI and BIOS
    gfxmodeEfi = "auto"; # Used if system boots in UEFI mode
    gfxmodeBios = "auto"; # Used if system boots in BIOS mode

    # Set the theme
    theme = "${cybergrub-theme}/CyberGRUB-2077";

    extraConfig = ''
      # Load modules based on platform (UEFI or BIOS)
      if [ "$grub_platform" = "efi" ]; then
        insmod efi_gop
      else
        insmod vbe
      fi
      insmod all_video
      insmod gfxterm

      # Try 1920x1080, fall back to auto if it fails
      set gfxmode=1920x1080,auto
      set gfxpayload=keep

      terminal_output console
      terminal_output gfxterm
    '';
  };

  boot.loader.efi = {
    canTouchEfiVariables = true; # Allow NixOS to modify EFI variables
    efiSysMountPoint = "/boot"; # Ensure this matches your EFI partition mount point
  };

  boot = {
    plymouth = {
      enable = true;
      theme = "spinner_alt"; # Set the theme to spinner_alt
      themePackages = with pkgs; [
        (adi1090x-plymouth-themes.override { selected_themes = [ "spinner_alt" ]; })
      ]; # Provide the theme package
    };
    initrd = {
      verbose = false;
      systemd.enable = true; # Keep early Plymouth support
      availableKernelModules = [ "i915" ]; # Adjust for your GPU
    };
    consoleLogLevel = 0;
    kernelParams = [
      "quiet"
      "splash"
      "loglevel=3"
      "rd.udev.log_level=3"
      "rd.systemd.show_status=auto"
    ];
    loader = {
      timeout = 5; # Keep GRUB visible for 5 seconds
    };
  };

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than +9";
  };

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";
  time.hardwareClockInLocalTime = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
  ];
  i18n.extraLocaleSettings = {
    LANG = "en_US.UTF-8";
    LANGUAGE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_COLLATE = "en_US.UTF-8";
    LC_MESSAGES = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  services.xserver.videoDrivers = [
    "amdgpu"
    "intel"
  ];

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm = {
    enable = true;
    wayland = true;
  };
  services.xserver.desktopManager.gnome.enable = true;

  services.dbus.enable = true;
  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  hardware.graphics.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.necryl = {
    isNormalUser = true;
    description = "Necryl";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  services.flatpak.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    neofetch
    steam-run
    git
    (adi1090x-plymouth-themes.override { selected_themes = [ "spinner_alt" ]; })
    pciutils
    kdePackages.dolphin
    kdePackages.konsole
    wineWowPackages.stable
    #  wget
    waybar
    rofi-wayland
    swww
    dunst
    libnotify
    gpaste
    tree
    kmonad
    gnumeric
    libreoffice
  ];

  # Enable envfs
  services.envfs.enable = true;

  programs.nix-ld.enable = true;

  environment.variables.EDITOR = "hx";

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    font-awesome
  ];

  home-manager.backupFileExtension = "backup";

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}

# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  inputs,
  ...
}:
let
  cybergrub-theme = inputs.cybergrub-theme;
in

{
  # Bootloader.
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    device = "nodev"; # For UEFI, set to "nodev" instead of a disk
    efiSupport = true;
    useOSProber = false; # Optional: Detect other operating systems

    # Flexible resolution detection for both UEFI and BIOS
    gfxmodeEfi = "1920x1080,1600x900,1280x720,auto";
    gfxmodeBios = "1920x1080,1600x900,1280x720,auto";

    gfxpayloadEfi = "keep";
    gfxpayloadBios = "keep";

    # Set the theme
    theme = "${cybergrub-theme}/CyberGRUB-2077";
    splashImage = ../images/NixOS_Backdrop.png;

    extraConfig = ''
      # Load modules based on platform (UEFI or BIOS)
      if [ "$grub_platform" = "efi" ]; then
        insmod efi_gop
      else
        insmod vbe
      fi
      insmod all_video
      insmod gfxterm


      terminal_output console
      terminal_output gfxterm
    '';
  };

  boot.loader.efi = {
    canTouchEfiVariables = true; # Allow NixOS to modify EFI variables
    efiSysMountPoint = "/boot"; # Ensure this matches your EFI partition mount point
  };

  boot.plymouth = {
    enable = true;
    theme = "spinner_alt"; # Set the theme to spinner_alt
    themePackages = with pkgs; [
      (adi1090x-plymouth-themes.override { selected_themes = [ "spinner_alt" ]; })
    ]; # Provide the theme package
  };
  boot.initrd = {
    verbose = false;
    systemd.enable = true; # Keep early Plymouth support
  };

  boot.kernelParams = [
    "nohibernate" # Disable hibernation in the kernel

    "quiet"
    "splash"
    "loglevel=3"
    "rd.udev.log_level=3"
    "rd.systemd.show_status=auto"
  ];
  boot.consoleLogLevel = 0;

  # boot.loader.systemd-boot.configurationLimit = 9;
  boot.loader.grub.configurationLimit = 9; # when using grub instead of systemd

  boot.supportedFilesystems = [ "ntfs" ];
  boot.loader = {
    timeout = 5; # Keep GRUB visible for 5 seconds
  };

  # Set the console font to Terminus
  console.font = "ter-v16n";

  # Set the 16-color TTY palette
  console.colors = [
    "010614"
    "ff8c35"
    "38ffc9"
    "ffdb1a"
    "ec8129"
    "7208f4"
    "2ba5ff"
    "73B2FF"
    "3e7bdc"
    "ff7200"
    "00fdbb"
    "7300ff"
    "ec8129"
    "fdd600"
    "5db6ff"
    "E8F2FF"
  ];

  # garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d"; # Deletes generations older than 7 days
  };

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";
  time.hardwareClockInLocalTime = true;

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_IN";
    supportedLocales = [ "all" ];
  };
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IN";
    LC_IDENTIFICATION = "en_IN";
    LC_MEASUREMENT = "en_IN";
    LC_MONETARY = "en_IN";
    LC_NAME = "en_IN";
    LC_NUMERIC = "en_IN";
    LC_PAPER = "en_IN";
    LC_TELEPHONE = "en_IN";
    LC_TIME = "en_IN";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS and avahi to print documents.
  services.printing = {
    enable = true;
    drivers = [ pkgs.hplip ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true; # Enable mDNS for hostname resolution
    openFirewall = true; # Open firewall for mDNS
  };

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
      "video"
      "nixconfig"
      "nixos-admins"
    ];
    initialPassword = "changeme";
    packages = with pkgs; [
      #  thunderbird
    ];
  };

  users.users.work = {
    isNormalUser = true;
    description = "Work";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "nixconfig"
      "nixos-admins"
    ];
    initialPassword = "changeme";
  };

  environment.variables = {
    EDITOR = "hx";
  };

  services.flatpak.enable = true;
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      ## Put here any library that is required when running a package
      (pkgs.runCommand "steamrun-lib" { } "mkdir $out; ln -s ${pkgs.steam-run.fhsenv}/usr/lib64 $out/lib")
    ];
  };

  # avoid pid file error
  systemd.services.avahi-daemon.serviceConfig = {
    ExecStartPre = "+${pkgs.coreutils}/bin/rm -f /run/avahi-daemon/pid";
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  nix.settings.download-buffer-size = 524288000;

  # List packages installed in system profile. To search, run:
  # $ nix search wget

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

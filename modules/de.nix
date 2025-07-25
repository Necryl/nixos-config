{
  config,
  pkgs,
  inputs,
  ...
}:
{
  hardware.graphics = {
    package = pkgs.mesa;

    # if you also want 32-bit support (e.g for Steam)
    enable32Bit = true;
    package32 = pkgs.pkgsi686Linux.mesa;
  };
  # Enable the login manager
  services.displayManager.cosmic-greeter.enable = true;
  # Enable the COSMIC DE itself
  services.desktopManager.cosmic.enable = true;
  # Enable XWayland support in COSMIC
  services.desktopManager.cosmic.xwayland.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-cosmic
      xdg-desktop-portal-gtk
      xdg-desktop-portal-kde
    ];
    config = {
      common = {
        default = [ "cosmic" ];
      };
    };
  };
}

{
  config,
  pkgs,
  inputs,
  cosmicLib,
  ...
}:
let
  inherit (cosmicLib.cosmic) mkRon;
in
{
  wayland.desktopManager.cosmic.wallpapers = [
    {
      filter_by_theme = true;
      filter_method = cosmicLib.cosmic.mkRON "enum" "Lanczos";
      output = "all";
      rotation_frequency = 600;
      sampling_method = cosmicLib.cosmic.mkRON "enum" "Alphanumeric";
      scaling_mode = cosmicLib.cosmic.mkRON "enum" {
        value = [
          (cosmicLib.cosmic.mkRON "tuple" [
            0.5
            1.0
            (cosmicLib.cosmic.mkRON "raw" "0.345354352")
          ])
        ];
        variant = "Fit";
      };
      source = cosmicLib.cosmic.mkRON "enum" {
        value = [
          "../../images/rashed-alakroka-cyborg-plus-city.png"
        ];
        variant = "Path";
      };
    }
  ];

  # Enable Qt theming
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style = {
      name = "kvantum";
    };
  };
}

{ } {
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixssd-root";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/nixssd-boot";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-partlabel/nixssd-swap"; }
  ];

}

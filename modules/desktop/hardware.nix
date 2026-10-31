{
  ##### Hardware #####
  # Common to every graphical machine. CPU- or form-factor-specific bits are
  # in modules/hardware/ (laptop.nix, nvidia.nix).
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.bluetooth.enable = true;
  # Radio stays off after boot (the module default is on).
  hardware.bluetooth.powerOnBoot = false;
  hardware.enableRedistributableFirmware = true;
  services.printing.enable = false;
  zramSwap.enable = true;
  boot.kernelModules = [ "sg" ];   # MakeMKV reads discs through the SCSI generic driver

  services.fwupd.enable = true;     # firmware updates via LVFS
}

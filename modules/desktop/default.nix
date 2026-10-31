# A graphical machine: Hyprland, audio, fonts, common hardware
# support and the system-wide apps. The per-user side (Hyprland config,
# the bar, apps) is in home/desktop/.
{ pkgs, ... }:
{
  imports = [
    ./session.nix
    ./programs.nix
  ];

  ##### Audio #####
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;   # 32-bit Steam titles
    pulse.enable = true;
    wireplumber.enable = true;  # provides wpctl, used by hypr/binds.lua
  };
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;  # realtime scheduling; prevents crackling under load

  ##### Fonts #####
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    liberation_ttf
    nerd-fonts.jetbrains-mono
  ];

  ##### Hardware #####
  # Common to every graphical machine. CPU- or form-factor-specific bits are
  # in modules/hardware/ (laptop.nix, nvidia.nix).
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;  # radio stays off after boot
  hardware.enableRedistributableFirmware = true;
  services.printing.enable = false;
  zramSwap.enable = true;
  boot.kernelModules = [ "sg" ];   # MakeMKV reads discs through the SCSI generic driver

  services.fwupd.enable = true;     # firmware updates via LVFS
}

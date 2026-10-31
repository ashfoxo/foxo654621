# A graphical machine: Hyprland, audio, fonts, common hardware
# support and the system-wide apps. The per-user side (Hyprland config,
# the bar, apps) is in home/desktop/.
{
  imports = [
    ./session.nix
    ./audio.nix
    ./fonts.nix
    ./hardware.nix
    ./programs.nix
  ];
}

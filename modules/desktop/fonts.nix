{ pkgs, ... }:
{
  ##### Fonts #####
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    liberation_ttf
    nerd-fonts.jetbrains-mono
  ];
}

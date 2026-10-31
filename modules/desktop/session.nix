let
  # Shared with home/default.nix and hyprland.nix. Edit lib/session-vars.nix.
  sessionVars = import ../../lib/session-vars.nix;
in
{
  ##### Desktop #####
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Boot straight into Hyprland, which then locks itself (hyprland.nix)
  services.displayManager.autoLogin = {
    enable = true;
    user = "arlo";
  };
  services.displayManager.defaultSession = "hyprland";

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Portals under Hyprland: its own portal for screenshots/screencast, KDE's
  # for file pickers (Hyprland's has none) and settings like dark mode. Your
  # nixpak apps open files through the FileChooser portal, so this matters.
  # Plasma keeps its own portal config; this file only applies to Hyprland.
  xdg.portal.config.hyprland = {
    default = [ "hyprland" "kde" ];
    "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
  };

  # PAM services
  # hyprlock: touch yak-olive to unlock (u2f is "sufficient", same as sudo).
  # Typing your password still works as a fallback, and a typed password
  # also unlocks GPG via pam_gnupg. A touch can't unlock GPG, so after a
  # touch unlock, pass / Bitwarden ask for the GPG passphrase themselves.
  # (The u2f and sudo settings themselves are in core/hardening.nix.)
  security.pam.services.hyprlock = {
    u2fAuth = true;
    gnupg.enable = true;
  };
  security.pam.services.sddm.gnupg.enable = true;

  environment.sessionVariables = sessionVars;
}

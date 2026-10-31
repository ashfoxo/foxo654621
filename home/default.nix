{ lib, config, pkgs, ... }:

let
  # Shared with modules/desktop/session.nix and hyprland.nix. Edit
  # lib/session-vars.nix.
  sessionVars = import ../lib/session-vars.nix;
in
{
  imports = [
    ./desktop
  ];

  home.username = "arlo";
  home.homeDirectory = "/home/arlo";

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  services.pass-secret-service = {
    enable = true;
    storePath = "/home/arlo/.password-store";
  };

  # Plasma's ksecretd also tries to own org.freedesktop.secrets. Tell it not to,
  # so pass-secret-service always wins the name and apps like Bitwarden never
  # fall back to another store.
  home.activation.disableKwalletSecretService =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
        --file kwalletrc --group org.freedesktop.secrets \
        --key apiEnabled false
    '';

  programs.bash.enable = true;

  home.sessionVariables = sessionVars;

  home.file.".config/plasma-workspace/env/session-vars.sh".text =
    (lib.concatStringsSep "\n"
      (lib.mapAttrsToList (n: v: ''export ${n}="${v}"'') sessionVars)) + "\n";
}

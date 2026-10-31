{ inputs, ... }:
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  # Pass nixpak input into home-manager modules (apps.nix / webapps.nix)
  home-manager.extraSpecialArgs = { inherit (inputs) nixpak; };
  home-manager.users.arlo = import ../home;

  # First activation almost always collides with files Plasma or the
  # installer already wrote (~/.config/... etc). With this, the
  # offender is renamed to *.hm-backup and the build continues.
  home-manager.backupFileExtension = "hm-backup";
}

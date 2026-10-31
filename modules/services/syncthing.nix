{
  # Syncthing's sync port, open to NetBird peers only (home/desktop/syncthing.nix).
  # The web UI stays on localhost.
  networking.firewall.interfaces.wt0.allowedTCPPorts = [ 22000 ];
}

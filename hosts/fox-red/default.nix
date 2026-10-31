# fox-red: the Hetzner VPS. Brought over unchanged from redfox-server; every
# other file in this folder is exactly as it was there. It doesn't use the
# shared modules/, has its own sops keys (.sops.yaml here), and is deployed
# from the laptop with ./hosts/fox-red/deploy.sh.
{ inputs, ... }:
{
  imports = [
    ./configuration.nix
    inputs.sops-nix.nixosModules.sops
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
}

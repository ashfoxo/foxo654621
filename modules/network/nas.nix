# The Ark NAS (SMB), mounted at ~/ark only while the laptop is on the home
# Wi-Fi, and gone when it leaves.
#
# What is secret stays out of this public repo: the Wi-Fi names, the NAS
# address, its share name and login, and the router's MAC address are keys in
# secrets/secrets.yaml (encrypted with sops). Add them with
# `./sops.sh secrets/secrets.yaml`, BEFORE turning this on (fox.nas.enable):
#
#   ark-user:         <SMB user name>
#   ark-password:     <SMB password>
#   ark-ip:           192.168.x.x            (the NAS)
#   ark-share:        <share name>           (smbclient -L //<ip> -U <user>)
#   ark-gateway-mac:  aa:bb:cc:dd:ee:ff      (the home router, see below)
#   ark-ssids: |
#     <Wi-Fi name 1>
#     <Wi-Fi name 2>
#
# Router MAC, while on the home Wi-Fi:
#   ip neigh show $(ip route | awk '/default/{print $3}')
#
# It mounts only when BOTH the Wi-Fi name and the router's MAC address match,
# so a look-alike hotspot or a hotel network that also uses the same address
# range does not get the NAS password. (A MAC address can be spoofed, so this
# is a strong hint, not proof.) Everything is SMB 3 with encryption (seal); if
# the NAS can't do that the mount fails instead of falling back to plain text.
#
# Mullvad blocks local devices. Instead of `mullvad lan set allow` (which opens
# the whole local network on every network), a tiny firewall table lets through
# only this one address and port, only while the mount is up. Same trick as
# mullvad-netbird-rules in vpn.nix.
#
# No name lookup, no broadcasts, no automount: on other networks nothing tries
# to reach the NAS, and no ~/ark folder exists.
{ config, pkgs, lib, ... }:

let
  cfg = config.fox.nas;
  user = "arlo";
  mountPoint = "/home/${user}/ark";
  secret = name: config.sops.secrets.${name}.path;
  credentials = config.sops.templates."ark-credentials".path;

  reconcile = pkgs.writeShellApplication {
    name = "ark-reconcile";
    runtimeInputs = with pkgs; [
      coreutils gnugrep gawk iproute2 nftables util-linux networkmanager cifs-utils
    ];
    text = ''
      mp=${mountPoint}

      leave() {
        if mountpoint -q "$mp"; then
          umount -l "$mp" || true
        fi
        rmdir "$mp" 2>/dev/null || true
        nft delete table inet mullvad-ark 2>/dev/null || true
      }

      # Which Wi-Fi are we on right now?
      ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | head -n1 | cut -d: -f2- || true)
      if [ -z "$ssid" ] || ! grep -qxF "$ssid" ${secret "ark-ssids"}; then
        leave
        exit 0
      fi

      # Is the router the one we expect? (ping once so it is in the neighbour table)
      gw=$(ip route show default | awk '/default/ { print $3; exit }')
      if [ -z "$gw" ]; then
        leave
        exit 0
      fi
      ping -c1 -W2 "$gw" >/dev/null 2>&1 || true
      mac=$(ip neigh show "$gw" | awk '{ for (i = 1; i < NF; i++) if ($i == "lladdr") print $(i + 1) }' | head -n1)
      want=$(tr -d '[:space:]' < ${secret "ark-gateway-mac"})
      if [ -z "$mac" ] || [ "''${mac,,}" != "''${want,,}" ]; then
        leave
        exit 0
      fi

      if mountpoint -q "$mp"; then
        exit 0
      fi

      ip=$(tr -d '[:space:]' < ${secret "ark-ip"})
      share=$(tr -d '\n' < ${secret "ark-share"})

      # Let exactly this address and port past Mullvad's firewall.
      nft -f - <<NFT
      table inet mullvad-ark
      delete table inet mullvad-ark
      table inet mullvad-ark {
        chain outgoing {
          type route hook output priority -199; policy accept;
          ip daddr $ip tcp dport 445 ct mark set 0x00000f41 meta mark set 0x6d6f6c65
        }
        chain incoming {
          type filter hook input priority -199; policy accept;
          ip saddr $ip tcp sport 445 ct mark set 0x00000f41
        }
      }
      NFT

      install -d -o ${user} -g users -m 0700 "$mp"
      uid=$(id -u ${user})
      gid=$(id -g ${user})
      if ! timeout 30 mount.cifs "//$ip/$share" "$mp" -o \
        "credentials=${credentials},uid=$uid,gid=$gid,vers=3.1.1,seal,rw,nosuid,nodev,noexec,file_mode=0600,dir_mode=0700,soft,echo_interval=10"; then
        echo "ark: mount failed (wrong share or login, or the NAS lacks SMB 3 encryption)" >&2
        leave
        exit 1
      fi
    '';
  };
in
{
  options.fox.nas.enable = lib.mkEnableOption "the Ark NAS mount on the home Wi-Fi (needs the ark-* secrets)";

  config = lib.mkIf cfg.enable {
    boot.supportedFilesystems = [ "cifs" ];

    sops.secrets = lib.genAttrs
      [ "ark-user" "ark-password" "ark-ip" "ark-share" "ark-gateway-mac" "ark-ssids" ]
      (_: { });

    # The login, as a file only root can read, for mount.cifs.
    sops.templates."ark-credentials".content = ''
      username=${config.sops.placeholder.ark-user}
      password=${config.sops.placeholder.ark-password}
    '';

    systemd.services.ark-mount = {
      description = "Mount or unmount the Ark NAS for the current network";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe reconcile;
        TimeoutStartSec = 60;
      };
    };

    # NetworkManager runs this on every connection change. It only has to wake
    # the service above: dispatcher scripts are killed after a few seconds.
    networking.networkmanager.dispatcherScripts = [{
      type = "basic";
      source = pkgs.writeShellScript "ark-dispatch" ''
        case "$2" in
          up|down|dhcp4-change|connectivity-change)
            ${pkgs.systemd}/bin/systemctl start --no-block ark-mount.service ;;
          *) ;;
        esac
      '';
    }];
  };
}

{ config, pkgs, ... }:
{
  # --- File transfer ---
  # "phone" is the Pixel over NetBird (Termux sshd on 8022). The old name
  # still works as an alias.
  #
  # Private key for send/fetch, in its own sops file (encrypted to the same
  # recipients as secrets.yaml). Decrypted at boot to
  # /run/secrets/phone-ssh-key, readable only by arlo.
  sops.secrets.phone-ssh-key = {
    sopsFile = ../../secrets/phone-ssh-key.enc;
    format = "binary";
    owner = "arlo";
    mode = "0400";
  };

  programs.ssh.extraConfig = ''
    Host phone ferret-amber
      HostName 100.73.132.91
      Port 8022
      # NetBird builds the tunnel on first use (lazy connections), so the
      # first attempt can fail while it comes up. Retry instead of giving up.
      ConnectTimeout 15
      ConnectionAttempts 3
      # Dedicated key for this one job; Bitwarden isn't involved.
      IdentityFile ${config.sops.secrets.phone-ssh-key.path}
      IdentitiesOnly yes
      IdentityAgent none
  '';

  environment.systemPackages = with pkgs; [
    # Phone file transfer.
    # send:  ~/tailnet/*  -> phone:~/ssh/
    # fetch: phone:~/ssh/* -> ~/tailnet/
    (writeShellScriptBin "send" ''
      shopt -s nullglob
      files=(~/tailnet/*)
      if [ ''${#files[@]} -eq 0 ]; then
        echo "send: ~/tailnet is empty, nothing to send" >&2
        exit 1
      fi
      exec ${openssh}/bin/scp -r "''${files[@]}" "''${1:-phone}:ssh/"
    '')
    (writeShellScriptBin "fetch" ''
      mkdir -p ~/tailnet
      exec ${openssh}/bin/scp -r "''${1:-phone}:ssh/*" ~/tailnet/
    '')
  ];
}

{ pkgs, lib, ... }:

# ActivityWatch: time tracking on the laptop, plus the phone's data, in one
# dashboard at http://localhost:5600 (launcher: "ActivityWatch").
#
#   awatcher     tracks the focused window and AFK time (works on Hyprland;
#                the stock window watcher doesn't do Wayland)
#   aw-server    stores it, serves the dashboard
#   aw-fetch     copies the phone's sync folder over SSH, then imports it.
#                Runs every 30 minutes on its own, or run it by hand.
#
# Phone side: the Android app's Sync writes to
#   /storage/emulated/0/Documents/ActivityWatchSync
# and aw-fetch pulls that folder into ~/ActivityWatchSync.

let
  # nixpkgs 26.05 ships 0.13; the phone's sync format needs 0.14's aw-sync.
  # This uses upstream's prebuilt v0.14.1 Linux release instead of compiling
  # (the source build is slow on this CPU). Only aw-server and aw-sync are
  # taken from it; they need nothing beyond glibc. The dashboard is built in.
  # Drop this and use pkgs.aw-server-rust once nixpkgs has 0.14.
  awServer = pkgs.stdenv.mkDerivation {
    pname = "aw-server-rust-bin";
    version = "0.14.1";

    src = pkgs.fetchurl {
      url = "https://github.com/ActivityWatch/activitywatch/releases/download/v0.14.1/activitywatch-v0.14.1-linux-x86_64.zip";
      hash = "sha256-IRUUqJEsCjmajHBIEBtpngov7bXoG17SJDBNXI4JHyo=";
    };

    nativeBuildInputs = with pkgs; [ unzip autoPatchelfHook ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib ];

    unpackPhase = ''
      unzip -q $src 'activitywatch/aw-server-rust/*'
    '';

    installPhase = ''
      install -Dm755 activitywatch/aw-server-rust/aw-server-rust $out/bin/aw-server
      install -Dm755 activitywatch/aw-server-rust/aw-sync $out/bin/aw-sync
    '';

    meta = {
      mainProgram = "aw-server";
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
    };
  };

  phoneDir = "/storage/emulated/0/Documents/ActivityWatchSync";
  syncDir = "$HOME/ActivityWatchSync";

  awFetch = pkgs.writeShellApplication {
    name = "aw-fetch";
    runtimeInputs = with pkgs; [ rsync openssh coreutils awServer ];
    text = ''
      mkdir -p "${syncDir}"
      # Copy only; never delete. The laptop's own folder lives here too.
      rsync -a "phone:${phoneDir}/" "${syncDir}/"
      # Import the phone's buckets into the local server.
      AW_SYNC_DIR="${syncDir}" aw-sync sync --mode pull
      echo "aw-fetch: phone data imported"
    '';
  };
in
{
  services.activitywatch = {
    enable = true;
    package = awServer;
    # Defaults: idle after 3 minutes without input. To change, run
    # `awatcher --help` and add flags to extraOptions, e.g.
    #   extraOptions = [ "--idle-timeout" "300" ];
    watchers.awatcher.package = pkgs.awatcher;
  };

  # awatcher needs a running desktop. Start it with the graphical session,
  # not at boot, and retry if it starts early.
  systemd.user.services.activitywatch-watcher-awatcher = {
    Unit = {
      After = lib.mkForce [ "activitywatch.service" "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = lib.mkForce [ "graphical-session.target" ];
  };

  # Pull the phone's data every 30 minutes. If the phone isn't reachable
  # (sshd not running in Termux, NetBird off), the run just fails quietly
  # and the next one tries again.
  systemd.user.services.aw-fetch = {
    Unit.Description = "Import ActivityWatch data from the phone";
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe awFetch;
    };
  };
  systemd.user.timers.aw-fetch = {
    Unit.Description = "Import ActivityWatch data from the phone every 30 minutes";
    Timer = {
      OnBootSec = "5min";
      OnUnitActiveSec = "30min";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  home.packages = [ awFetch awServer ];

  # Dashboard in the launcher. LibreWolf shares the host network, so it can
  # reach the local server.
  xdg.desktopEntries.activitywatch = {
    name = "ActivityWatch";
    comment = "Screen time across laptop and phone";
    exec = "librewolf http://localhost:5600";
    icon = "preferences-system-time";
    categories = [ "Utility" ];
  };
}

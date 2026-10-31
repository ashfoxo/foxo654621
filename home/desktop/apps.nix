{ pkgs, lib, config, nixpak, osConfig, ... }:

# Desktop apps for arlo. Grouped by what they're for.
#
# Sandboxed apps come from sandboxes.nix (nixpak/bubblewrap). Each one gets
# its own home in ~/.local/share/sandboxes/<name> and can only reach files
# in ~/sandbox_folders/<name> (shown inside as ~/Shared). qBittorrent also
# gets ~/torrents.
#
# Elsewhere:
#   modules/desktop/programs.nix  CLI tools (ffmpeg, btop, adb, ...), Steam, and the two
#                                 apps outside Mullvad: Zoom and the clean Firefox
#   helpers.nix        Hyprland helpers (launcher, bar, lock, screenshots)
#   webapps.nix        Chromium web apps (Tuta, Claude, Gmail, ...)
#   dev.nix, filen.nix, voicenotes.nix, activitywatch.nix

let
  sandboxes = import ./sandboxes.nix {
    inherit pkgs nixpak;
    extraGpuDev = osConfig.fox.desktop.sandboxGpuDevices;
    extraGpuEnv = osConfig.fox.desktop.sandboxGpuEnv;
  };
in
{
  home.packages = [

    # --- Browsers -----------------------------------------------------------
    sandboxes.mullvad-browser
    sandboxes.librewolf
    sandboxes.qutebrowser
    # Clean Firefox (unsandboxed, outside Mullvad) is in modules/desktop/programs.nix.

    # --- Communication ------------------------------------------------------
    sandboxes.signal-desktop
    sandboxes.telegram-desktop
    sandboxes.vesktop          # Discord

    # --- Media ---------------------------------------------------------------
    pkgs.feishin               # Navidrome music
    pkgs.fluent-reader         # RSS (AppImage; can't be sandboxed, see sandboxes.nix)
    pkgs.vlc

    # --- DVDs: rip to MKV, then compress -------------------------------------
    # MakeMKV: lossless rip of a disc to .mkv (unfree; free key while in beta,
    #   https://forum.makemkv.com/forum/viewtopic.php?t=1053).
    # HandBrake: shrink that .mkv (H.265 / AV1). Can also read DVDs directly.
    pkgs.makemkv
    pkgs.handbrake

    # --- Writing and notes -------------------------------------------------
    pkgs.notesnook
    pkgs.typora
    pkgs.libreoffice-qt6

    # --- Creative ------------------------------------------------------------
    pkgs.darktable
    pkgs.kdePackages.kdenlive

    # --- Radio -------------------------------------------------------------
    pkgs.chirp
    pkgs.wsjtx

    # --- Games ---------------------------------------------------------------
    sandboxes.prismlauncher    # Steam is in modules/desktop/programs.nix

    # --- Phone -------------------------------------------------------------
    pkgs.scrcpy                # mirror/control the phone: plug in USB, run `scrcpy`

    # --- Security ------------------------------------------------------------
    pkgs.bitwarden-desktop

    # --- Downloads -----------------------------------------------------------
    sandboxes.qbittorrent

    # --- Tools -------------------------------------------------------------
    pkgs.ghostty
    pkgs.vscodium
    pkgs.qdirstat              # disk usage map
  ]
  # NVIDIA hosts: a diagnostic for graphics inside the sandboxes (sandboxes.nix).
  ++ lib.optional (osConfig.fox.desktop.sandboxGpuDevices != [ ]) sandboxes.gl-check;

  # qBittorrent saves to ~/torrents. Its settings file lives in its sandbox
  # home and qBittorrent rewrites it, so instead of owning the file, set
  # just these keys on every rebuild. (qBittorrent writes its settings when
  # it quits, so quit it before the first rebuild after this change.)
  home.activation.qbittorrentSavePath =
    let
      conf = "${config.home.homeDirectory}/.local/share/sandboxes/qbittorrent/.config/qBittorrent/qBittorrent.conf";
      torrents = "${config.home.homeDirectory}/torrents";
      set = section: key: value:
        "run ${lib.getExe pkgs.crudini} --ini-options=nospace --set ${lib.escapeShellArg conf} ${section} ${lib.escapeShellArg key} ${lib.escapeShellArg value}";
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${lib.escapeShellArg torrents} "$(dirname ${lib.escapeShellArg conf})"
      ${set "BitTorrent" "Session\\DefaultSavePath" torrents}
      ${set "BitTorrent" "Session\\TempPathEnabled" "false"}
    '';
}

{ pkgs, lib, ... }:

# Default apps: what opens when you click a link or a file (xdg-open,
# Dolphin, links in other apps). Writes ~/.config/mimeapps.list.
#
# Keyboard-driven replacements are listed but commented out. To switch one
# on: uncomment its package in home.packages AND its lines in the defaults
# below, then comment out the line it replaces. Learn them one at a time.
#
# Check what opens a file type:  xdg-mime query default application/pdf
# Find a type for a file:        xdg-mime query filetype somefile.pdf

let
  browser = "mullvad-browser.desktop";
  pdf     = "okularApplication_pdf.desktop";
  image   = "org.kde.gwenview.desktop";
  media   = "vlc.desktop";
  text    = "codium.desktop";
  folder  = "org.kde.dolphin.desktop";
  archive = "org.kde.ark.desktop";

  # Keyboard-driven alternatives (see home.packages below):
  # pdf    = "org.pwmt.zathura.desktop";  # zathura: j/k scroll, / search, + - zoom
  # media  = "mpv.desktop";               # mpv: space pause, arrows seek, [ ] speed
  # image  = "imv.desktop";               # imv: arrows next/prev, + - zoom, f fullscreen
  # folder = "yazi.desktop";              # yazi: hjkl move, enter open, q quit

  # One app for a whole list of file types.
  forAll = app: types: lib.genAttrs types (_: app);
in
{
  home.packages = with pkgs; [
    # zathura
    # mpv
    # imv
    # yazi
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications =
      forAll browser [
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "text/html"
        "application/xhtml+xml"
      ]
      // forAll pdf [ "application/pdf" ]
      // forAll image [
        "image/png"
        "image/jpeg"
        "image/gif"
        "image/webp"
        "image/avif"
        "image/heic"
        "image/bmp"
        "image/tiff"
        "image/svg+xml"
      ]
      // forAll media [
        "video/mp4"
        "video/x-matroska"
        "video/webm"
        "video/quicktime"
        "video/x-msvideo"
        "audio/mpeg"
        "audio/ogg"
        "audio/opus"
        "audio/flac"
        "audio/x-wav"
        "audio/mp4"
        "audio/aac"
      ]
      // forAll text [
        "text/plain"
        "text/x-shellscript"
        "text/x-python"
        "text/x-csrc"
        "application/json"
        "application/x-yaml"
        "application/toml"
        "text/x-nix"
      ]
      // forAll "typora.desktop" [ "text/markdown" ]
      // forAll "writer.desktop" [
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        "application/msword"
        "application/vnd.oasis.opendocument.text"
        "application/rtf"
      ]
      // forAll "calc.desktop" [
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        "application/vnd.ms-excel"
        "application/vnd.oasis.opendocument.spreadsheet"
        "text/csv"
      ]
      // forAll "impress.desktop" [
        "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        "application/vnd.ms-powerpoint"
        "application/vnd.oasis.opendocument.presentation"
      ]
      // forAll folder [ "inode/directory" ]
      // forAll archive [
        "application/zip"
        "application/x-tar"
        "application/gzip"
        "application/x-compressed-tar"
        "application/x-7z-compressed"
        "application/x-xz-compressed-tar"
        "application/zstd"
      ]
      // forAll "webapp-tuta.desktop" [ "x-scheme-handler/mailto" ];
  };

  # Apps (Plasma, browsers) rewrite mimeapps.list when you pick "always open
  # with". This file is the source of truth, so overwrite their changes on
  # rebuild instead of failing over a stale mimeapps.list.hm-backup. To keep
  # a default you set by clicking, add it above.
  xdg.configFile."mimeapps.list".force = true;

  # Dolphin (and other KDE apps) find installed apps through a menu file
  # that only Plasma provides, so outside Plasma they think nothing can open
  # anything ("no default program"). This is the plain menu they look for:
  # every installed app, no categories. Plasma uses its own
  # plasma-applications.menu, so this doesn't change anything there.
  # If Dolphin still shows nothing after a rebuild, run `kbuildsycoca6` once.
  xdg.configFile."menus/applications.menu".text = ''
    <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
      "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
    <Menu>
      <Name>Applications</Name>
      <DefaultAppDirs/>
      <DefaultDirectoryDirs/>
      <Include><All/></Include>
    </Menu>
  '';
}

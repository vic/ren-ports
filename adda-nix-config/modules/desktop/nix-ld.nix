# games-nix-ld: nix-ld libraries (part of the games aspect)
{ ren, ... }:
{
  ren.aspects.games.nixos =
    { pkgs, ... }:
    {
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          alsa-lib
          at-spi2-atk
          at-spi2-core
          atk
          cairo
          cups
          curl
          dbus
          expat
          fontconfig
          freetype
          fuse3
          gdk-pixbuf
          glib
          gtk3
          icu
          libGL
          libappindicator-gtk3
          libdrm
          libglvnd
          libnotify
          libpulseaudio
          libunwind
          libusb1
          libuuid
          libxkbcommon
          libxml2
          libgbm
          mesa
          nspr
          nss
          openssl
          pango
          pipewire
          stdenv.cc.cc
          systemd
          vulkan-loader
          libX11
          libXScrnSaver
          libXcomposite
          libXcursor
          libXdamage
          libXext
          libXfixes
          libXi
          libXrandr
          libXrender
          libXtst
          libxcb
          libxkbfile
          libxshmfence
          zlib
        ];
      };
    };
}

# adda: David (Adda) Chocholatý on his own machines, and the aspects he brings to each of them.
{ ren, ... }:
{
  ren.user.adda = {
    description = "David (Adda) Chocholatý";
    nick = "Adda";
    realName = "David Chocholatý";
    aiRules = import ../../ai/_rules.nix;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG2LSB9oGPxpYWFwb+InQHS6KCei7iKfF1MEb+KN3NpT adda@fulgur-nixos"
    ];
  };

  ren.aspects.adda = {
    at = ren.user.adda;
    includes = with ren.aspects; [
      security
      virtualisation

      console
      vcs
      vcs-desktop
      addaSsh
      shells
      ai
      documentation
      syncthing
      kdeconnect

      desktop
      desktop-flatpak
      desktop-environments-plasma
      browsers
      xremap

      media
      media-music
      media-console
      media-desktop
      media-books

      development-console

      languages-nix

      editors-helix
    ];
  };

  # Desktop/GUI-only aspects that only make sense on an interactive development workstation, not a (headless) server.
  ren.aspects.workstation = {
    at = ren.lib.and [
      ren.user.adda
      (ren.lib.when (s: s.host.workstation))
    ];
    includes = with ren.aspects; [
      security-portmaster
      editors-clion
      editors-zed-editor
      editors-vscodium
      # editors-nvchad
      # den included `editors.pycharm`, whose content sits only in its `desktop` child, so PyCharm never landed:
      # editors-pycharm-desktop
      development-desktop
      development-android
      waydroid
      languages-c-cpp
      languages-haskell
      languages-latex
      languages-lua
      languages-markdown
      languages-ocaml
      languages-python
      languages-rust
    ];
  };
}

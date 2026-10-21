{ ren, ... }:
{
  ren.aspects.workstation = {
    includes = with ren.aspects; [
      hardware-audio
      hardware-bluetooth
      hardware-coolercontrol
      hardware-ddcutil
      hardware-keyboard
      desktop-style-stylix
      desktop-style-fonts
      virtualization-libvirt
      desktop-xserver
      desktop-xwayland
      desktop-gdm
      desktop-gnome
      desktop-xdg-portal
      app-terminals-alacritty
      app-terminals-kitty
      app-browsers-firefox
      app-browsers-chromium
      dev-security-opkssh-client
      network-syncthing-tray
      app-mail-protonmail
      app-productivity-obs-studio
      app-productivity-obsidian
      app-productivity-zathura
    ];
  };
}

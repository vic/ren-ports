# profiles (home-manager): the homes each profile brings; a profile at a host reaches the homes of its users
{ ren, ... }:
{
  ren.aspects.profile-dgxspark.includes = [
    ren.aspects.atuin
    ren.aspects.bash
    ren.aspects.blueman-applet
    ren.aspects.direnv
    ren.aspects.eza
    ren.aspects.firefox
    ren.aspects.glide
    ren.aspects.fuzzel
    ren.aspects.settings
    ren.aspects.git
    ren.aspects.gpg-agent
    ren.aspects.kitty
    ren.aspects.nix-index
    ren.aspects.nixgl
    ren.aspects.nix-your-shell
    ren.aspects.network-manager-applet
    ren.aspects.sops
    ren.aspects.starship
    ren.aspects.stylix
    ren.aspects.tmux
    ren.aspects.zellij
    ren.aspects.zellij-keybinds
  ];
  ren.aspects.profile-minimal.includes = [
    ren.aspects.settings
    ren.aspects.sops
    ren.aspects.kitty
    ren.aspects.zsh
    ren.aspects.git
  ];
  ren.aspects.profile-personal = {
    includes = [
      ren.aspects.emacs
      ren.aspects.env
      ren.aspects.git
      ren.aspects.mail
      ren.aspects.obsidian
      ren.aspects.ssh
    ];
    homeManager =
      { lib, ... }:
      {
        swarselsystems.trayApplets.obsidian.enable = lib.swarselsystems.mkStrong true;
      };
  };
  ren.aspects.profile-public = {
    includes = [
      ren.aspects.attic-client
      ren.aspects.atuin
      ren.aspects.kdeconnect
      ren.aspects.khal
      ren.aspects.nixgl
      ren.aspects.obs-studio
      ren.aspects.opkssh
      ren.aspects.spotify-player
      ren.aspects.swayosd
      ren.aspects.tmux
      ren.aspects.vesktop
      ren.aspects.shikane
      ren.aspects.syncthing-tray
      ren.aspects.waybar
    ];
    homeManager.swarselsystems.trayApplets.obsidian.enable = false;
  };
  ren.aspects.profile-public-small = {
    includes = [
      ren.aspects.anki
      ren.aspects.tray-applets
      ren.aspects.blueman-applet
      ren.aspects.custom-packages
      ren.aspects.desktop
      ren.aspects.direnv
      ren.aspects.element
      ren.aspects.eza
      ren.aspects.firefox
      ren.aspects.glide
      ren.aspects.fuzzel
      ren.aspects.settings
      ren.aspects.gnome-keyring
      ren.aspects.gpg-agent
      ren.aspects.kitty
      ren.aspects.nix-index
      ren.aspects.nix-your-shell
      ren.aspects.network-manager-applet
      ren.aspects.packages
      ren.aspects.password-store
      ren.aspects.pedantix
      ren.aspects.programs
      ren.aspects.spicetify
      ren.aspects.starship
      ren.aspects.stylix
      ren.aspects.symlink
      ren.aspects.yubikey-touch-detector
      ren.aspects.zellij
      ren.aspects.zellij-keybinds
      ren.aspects.zsh
    ];
    homeManager.swarselsystems.trayApplets.obsidian.enable = false;
  };
}

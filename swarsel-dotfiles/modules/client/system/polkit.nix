{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.polkit.nixos =
    {
      variant,
      lib,
      ...
    }:
    {
    config.security = {
      # pki.certificateFiles = [
      #   config.sops.secrets.harica-root-ca.path
      # ];
      pam.services = lib.mkIf (!variant.minimal) {
        login.u2fAuth = true;
        sshd.u2fAuth = false;
        sudo.u2fAuth = true;
        swaylock = {
          fprintAuth = false;
          u2fAuth = true;
        };
      };
      polkit.enable = lib.mkIf (!variant.minimal) true;

      sudo.extraConfig = ''
        Defaults insults
        Defaults    env_keep+=SSH_AUTH_SOCK
      ''
      + lib.optionalString (!variant.minimal) ''
        Defaults    env_keep+=XDG_RUNTIME_DIR
        Defaults    env_keep+=WAYLAND_DISPLAY
      '';
    };
  };
}

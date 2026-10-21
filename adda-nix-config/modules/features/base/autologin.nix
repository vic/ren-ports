# tty1 autologin of a host's `ttyAutologin` user (always) or `vmAutologin` user (only in `nixos-rebuild build-vm`).
{ ren, ... }:
let
  inherit (ren.lib) and when;
  # From https://discourse.nixos.org/t/autologin-for-single-tty/49427/2
  getty =
    username:
    { pkgs, config, ... }:
    {
      systemd.services."getty@tty1" = {
        overrideStrategy = "asDropin";
        serviceConfig.ExecStart = [
          ""
          "@${pkgs.util-linux}/sbin/agetty agetty --login-program ${config.services.getty.loginProgram} --autologin ${username} --noclear --keep-baud %I 115200,38400,9600 $TERM"
        ];
      };
    };
  with' =
    f:
    and [
      ren.kinds.host
      (when (s: s.host.${f} != null))
    ];
in
{
  ren.aspects.tty-autologin = {
    at = with' "ttyAutologin";
    nixos = { host, ... }: { imports = [ (getty host.ttyAutologin.name) ]; };
  };
  ren.aspects.vm-autologin = {
    at = with' "vmAutologin";
    nixos = { host, ... }: { virtualisation.vmVariant = getty host.vmAutologin.name; };
  };
}

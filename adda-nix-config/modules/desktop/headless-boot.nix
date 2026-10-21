# desktop-headlessBoot: graphical session installed but inert at boot
{ ren, ... }:
{
  # Keeps a full graphical session installed but *inert* at boot: the machine comes up in  multi-user.target (text
  # consoles only), and the display manager is started by hand when someone actually wants a desktop. On an always-on
  # server that saves the few hundred MiB of RSS a Plasma session holds (greeter + kwin + plasmashell + the kded/baloo
  # tail) and the idle wakeups of a compositor nobody is looking at.
  #
  # Start the desktop later with `desktop-start`, stop it with `desktop-stop` (abbreviations from desktop.environments,
  # expanding to `sudo systemctl start|stop display-manager.service`. The session lands on tty7 (Ctrl+Alt+F7); the text
  # consoles on tty1-tty6 stay untouched. Until the display manager has been started once, VT7 does not exist yet, and
  # the kernel ignores a Ctrl+Alt+F7 for an unallocated VT (`set_console()` bails on  `!vc_cons_allocated(nr)`), so the
  # switch silently does nothing, as expected.
  ren.aspects.desktop-headlessBoot.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.services.displayManager.enable {
      # Every display-manager module (here services.displayManager.plasma-login-manager) sets
      #  this with a plain assignment, so overriding needs mkForce. multi-user.target never
      #  pulls display-manager.service, which is wanted by graphical.target alone.
      systemd.defaultUnit = lib.mkForce "multi-user.target";

      # nixpkgs only wires `autovt@tty1.service` into getty.target when no display manager is
      #  enabled (nixos/modules/services/ttys/getty.nix): a DM normally owns VT1, and a getty
      #  started there by `switch-to-configuration switch` would kill the running session.
      #  Here the greeter is on VT7 and nothing is started at boot, so without this VT1 — the
      #  VT the console is left sitting on after the boot messages — has no getty at all and
      #  looks hung (tty2-tty6 still work: logind spawns autovt@ttyN on VT switch).
      systemd.targets.getty.wants = [ "autovt@tty1.service" ];

      services.displayManager.plasma-login-manager.package =
        lib.mkIf config.services.displayManager.plasma-login-manager.enable
          (
            pkgs.kdePackages.plasma-login-manager.overrideAttrs (old: {
              # PLASMALOGIN_INITIAL_VT (default 1) is baked in at build time in two places that
              #  must agree: src/daemon/Display.cpp's fetchAvailableVt(), which takes that VT
              #  whenever logind reports no session on it, and services/plasmalogin.service.in,
              #  whose `Conflicts=getty@tty<N>.service` stops the getty there.
              # With the default of 1 that is exactly wrong here: started by hand from the text
              #  console, the greeter would stop getty@tty1 — killing the shell that ran the
              #  command — or, if started over SSH while tty1 sits at an idle login prompt, grab
              #  tty1 out from under it. tty7 is the traditional X VT and is outside logind's
              #  autovt range (NixOS spawns gettys on tty1-tty6 only), so nothing else claims it.
              cmakeFlags = (old.cmakeFlags or [ ]) ++ [ "-DPLASMALOGIN_INITIAL_VT=7" ];
            })
          );
    };
}

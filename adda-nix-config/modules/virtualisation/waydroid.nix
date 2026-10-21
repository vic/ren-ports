# virtualisation: Waydroid, with ~/documents/guitar exposed to Android as Internal storage -> Guitar
{ ren, ... }:
{
  ren.aspects.waydroid = {

    # Expose ~/documents/guitar to Android as Internal storage → Guitar.
    # Waydroid's `data` rbind only picks up submounts present when the container starts,
    #  so the mount must be ordered *before* waydroid-container (After= is invisible inside).
    # wantedBy, not requiredBy: a missing source folder must not keep Android from starting.
    # bindfs, not a plain bind: Android's storage stack refuses to descend into a foreign
    #  ext4 submount under /data/media (EINVAL, listed as empty). Same approach as
    #  waydroid-helper's shared folders: present files as media_rw (Android uid/gid 1023)
    #  with group rw so MediaProvider can write, while new files land on the host as the user.
    # Remount after each Android boot: MediaProvider reads through vold's non-recursive bind
    #  /mnt/pass_through/0/emulated, which drops pre-existing submounts but does receive
    #  later host mounts via propagation (host shared:1 -> container /data -> pass_through).
    os =
      {
        user,
        config,
        lib,
        pkgs,
        utils,
        ...
      }:
      let
        home = config.users.users.${user.name}.home;
        where = "${home}/.local/share/waydroid/data/media/0/Guitar";
        mountUnit = "${utils.escapeSystemdPath where}.mount";
      in
      {
        #https://nixos.org/wiki/Podman
        environment = {
          systemPackages = with pkgs; [
            waydroid-helper
          ];
        };

        virtualisation.waydroid = {
          enable = true;
        };

        system.fsPackages = [ pkgs.bindfs ]; # mount.fuse.bindfs on mount(8)'s helper path
        systemd.tmpfiles.rules = [ "d ${where} 0755 root root -" ];
        systemd.mounts = [
          {
            what = "${home}/documents/guitar";
            inherit where;
            type = "fuse.bindfs";
            options = lib.concatStringsSep "," [
              "force-user=1023"
              "force-group=1023"
              "perms=ug+rwX"
              "create-for-user=${user.name}"
              "create-for-group=${config.users.users.${user.name}.group}"
            ];
            before = [ "waydroid-container.service" ];
            wantedBy = [ "waydroid-container.service" ];
          }
        ];

        systemd.services.waydroid-guitar-remount = {
          description = "Remount the Waydroid Guitar share once Android's storage is up";
          after = [ mountUnit ];
          bindsTo = [ "waydroid-container.service" ];
          wantedBy = [ "waydroid-container.service" ];
          path = with pkgs; [
            procps
            gnugrep
          ];
          # Session starts (Android boots) aren't visible to systemd; poll MediaProvider instead.
          script = ''
            while sleep 5; do
              pid=$(pgrep --full --exact --newest com.android.providers.media.module) || continue
              mi=/proc/$pid/mountinfo
              grep --quiet ' /mnt/pass_through/0/emulated ' "$mi" || continue
              grep --quiet ' /mnt/pass_through/0/emulated/0/Guitar ' "$mi" && continue
              echo "MediaProvider $pid lacks the Guitar mount, remounting"
              systemctl restart ${lib.escapeShellArg mountUnit} || true
            done
          '';
        };
      };
  };
}

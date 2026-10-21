# libvirt: libvirtd/qemu settings, polkit, home-manager virt-manager config, persistence.
{ ... }:
{
  ren.aspects.virtualization-libvirt = {
    nixos =
      { host, pkgs, ... }:
      let
        user = host.system-owner.name;
      in
      {
        services = {
          qemuGuest.enable = true;
          spice-vdagentd.enable = true;
          spice-webdavd.enable = true;
        };

        virtualisation = {
          libvirtd = {
            enable = true;
            allowedBridges = [
              "br0"
              "virbr0"
              "virbr1"
            ];
            onBoot = "ignore";
            onShutdown = "shutdown";
            qemu = {
              swtpm.enable = true;
              runAsRoot = true;
              verbatimConfig = ''
                user = "${user}"
                group = "kvm"
                cgroup_device_acl = [
                  "/dev/null", "/dev/full", "/dev/zero",
                  "/dev/random", "/dev/urandom",
                  "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
                  "/dev/rtc","/dev/hpet", "/dev/sev",
                  "/dev/kvmfr0",
                  "/dev/vfio/vfio"
                ]
                hugetlbfs_mount = "/dev/hugepages"
                bridge_helper = "/run/wrappers/bin/qemu-bridge-helper"
              '';
            };
          };
          spiceUSBRedirection.enable = true;
        };

        security.polkit.extraConfig = ''
          polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.machine1.manage-machines" &&
              subject.isInGroup("libvirtd")) {
              return polkit.Result.YES;
            }
          });

          polkit.addRule(function(action, subject) {
            if (action.id == "org.libvirt.unix.manage" &&
              subject.isInGroup("libvirtd")) {
                return polkit.Result.YES;
            }
          });

          polkit.addRule(function(action, subject) {
            if (action.id == "org.libvirt.api.domain.start" &&
              subject.isInGroup("libvirtd")) {
                return polkit.Result.YES;
            }
          });
        '';
      };

  homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.spice-gtk
        pkgs.virtio-win
      ];

      dconf.settings = {
        "org/virt-manager/virt-manager/connections" = {
          autoconnect = [ "qemu:///system" ];
          uris = [ "qemu:///system" ];
        };

        "org/virt-manager/virt-manager" = {
          xmleditor-enabled = true;
          stats-update-interval = 1;
          console-accels = true;
        };

        "org/virt-manager/virt-manager/console" = {
          resize-guest = 1;
          scaling = 1;
        };

        "org/virt-manager/virt-manager/new-vm" = {
          graphics-type = "spice";
          cpu-default = "host-passthrough";
          storage-format = "qcow2";
        };

        "org/virt-manager/virt-manager/urls" = {
          isos = [ "/var/lib/libvirt/isos" ];
        };
      };

      xdg.configFile."looking-glass/client.ini".text = ''
        [app]
        shmFile=/dev/kvmfr0

        [input]
        rawMouse=yes
        escapeKey=KEY_RIGHTALT
      '';
    };

  persist.directories = [ "/var/lib/libvirt" ];
  };
}

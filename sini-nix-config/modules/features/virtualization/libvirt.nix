{ ... }:
{
  ren.aspects.virtualization-libvirt = {
    nixos =
      { host, pkgs, ... }:
      let
        user = host.system-owner.name;
      in
      {
        boot = {
          kernelModules = [
            "kvm"
            "vhost-net"
          ];

          kernel.sysctl = {
            "net.bridge.bridge-nf-call-iptables" = 0;
            "net.bridge.bridge-nf-call-arptables" = 0;
            "net.bridge.bridge-nf-call-ip6tables" = 0;
            "vm.nr_hugepages" = 1024;
          };

          kernelParams = [
            "default_hugepagesz=2M"
            "hugepagesz=2M"
            "transparent_hugepage=never"
            "mem_sleep_default=deep"

            # ACPI & Power Management
            "acpi_osi=Linux"
            "acpi=force"
            "acpi_enforce_resources=lax"

            # Performance
            "mitigations=off"
            "nowatchdog"
            "nmi_watchdog=0"
          ];
        };

        environment.systemPackages = [
          pkgs.libguestfs
          pkgs.spice
          pkgs.spice-gtk
          pkgs.spice-protocol
          pkgs.virt-manager
          pkgs.virt-viewer
          pkgs.virtio-win
          pkgs.win-spice
          pkgs.cloud-utils
          pkgs.bridge-utils
          pkgs.virtiofsd
          pkgs.local.looking-glass-client
          pkgs.qemu
          pkgs.OVMF
          pkgs.gvfs
          pkgs.swtpm
          pkgs.virglrenderer
        ];

        programs.virt-manager.enable = true;

        systemd.tmpfiles.rules = [
          "d /dev/hugepages 1770 root kvm -"
          "d /dev/shm 1777 root root -"
          "f /dev/shm/looking-glass 0660 ${user} kvm -"
        ];

        fileSystems."/dev/hugepages" = {
          device = "hugetlbfs";
          fsType = "hugetlbfs";
          options = [
            "mode=01770"
            "gid=kvm"
          ];
        };

        networking.firewall = {
          trustedInterfaces = [ "virbr0" ];
          allowedTCPPorts = [
            5900
            5901
            5902
            5903
            5904
            5905
          ];
          allowedTCPPortRanges = [
            {
              from = 5900;
              to = 5999;
            }
            {
              from = 61000;
              to = 61999;
            }
          ];
        };
      };
  };
}

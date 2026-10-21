# virtualisation: podman, libvirt, distrobox; GUI front ends on workstations
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.virtualisation = {
    os =
      {
        config,
        host,
        lib,
        pkgs,
        ...
      }:
      let
        # Hosts that run their own DNS server bound to the wildcard address
        #  (see aspects/services/dns/*) — mutually exclusive, at most one.
        hasHostResolver =
          config.services.adguardhome.enable
          || config.services.blocky.enable
          || config.services.pihole-ftl.enable
          || config.services.technitium-dns-server.enable;
      in
      {
        #https://nixos.org/wiki/Podman
        environment = {
          systemPackages =
            with pkgs;
            [
              #ventoy-full-qt

              distrobox-tui
              fuse-overlayfs

              podman-tui
              podman-compose

              # lilipod
            ]
            ++ lib.optionals host.workstation [
              boxbuddy
              distroshelf
              pods
              podman-desktop
            ];
        };

        boot.enableContainers = true;

        virtualisation = {
          containers = {
            enable = true;

            # aardvark-dns is off (below), so podman copies the host's
            #  /etc/resolv.conf into each container. On a resolver host that file
            #  points somewhere the container netns cannot reach (loopback, or
            #  MagicDNS on tailscale0), so point containers at the same resolver
            #  through the bridge gateway, which its wildcard bind already covers.
            containersConf.settings.containers = lib.optionalAttrs hasHostResolver {
              dns_servers = [ "10.88.0.1" ];
            };
          };

          podman = {
            # No aardvark-dns: it binds :53 on the bridge gateway (10.88.0.1) and
            #  loses that bind to any host resolver already holding *:53. Its only
            #  job is container-name -> container-IP records; stacks that need to
            #  address each other share a pod and talk over localhost instead.
            defaultNetwork.settings.dns_enabled = false;
            dockerCompat = true;
            dockerSocket.enable = true;
            enable = true;
          };

          libvirtd.enable = true;
        };

        # The podman module only opens :53 on the bridge for aardvark's own
        #  listener, so with it off the host resolver needs the hole instead.
        networking.firewall.interfaces."podman0" = lib.mkIf hasHostResolver {
          allowedUDPPorts = [ 53 ];
          allowedTCPPorts = [ 53 ];
        };

        programs.virt-manager.enable = host.workstation;
      };

    account =
      { config, lib, ... }:
      {
        extraGroups =
          (lib.optional config.virtualisation.podman.enable "podman")
          ++ (lib.optional config.virtualisation.libvirtd.enable "libvirtd");
      };

    homeManager = {
      # services.podman = { };
      programs.distrobox = {
        enable = true;
        containers = {
          #   python-project = {
          #     image = "fedora:40";
          #     additional_packages = "python3 git";
          #     init_hooks = "pip3 install numpy pandas torch torchvision";
          #   };

          #   common-debian = {
          #     image = "debian:13";
          #     entry = true;
          #     additional_packages = "git";
          #     init_hooks = [
          #       "ln -sf /usr/bin/distrobox-host-exec /usr/local/bin/docker"
          #       "ln -sf /usr/bin/distrobox-host-exec /usr/local/bin/docker-compose"
          #     ];
          #   };

          #   office = {
          #     clone = "common-debian";
          #     additional_packages = "libreoffice onlyoffice";
          #     entry = true;
          #   };

          #   random-things = {
          #     clone = "common-debian";
          #     entry = false;
          #   };
        };
      };
    };
    abbreviations =
      { pkgs, ... }:
      {
        dk = "docker";
        pm = "${addax.getExeName pkgs.podman}";
      };

  };
}

{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.mpd = sw.distributed (
    {
      globals-defs,
      host,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
      confLib = sw.confLibOf { inherit host globals config; };
      inherit (config.swarselsystems) sopsFile;
      inherit
        (confLib.gen {
          name = "mpd";
          port = 6600;
        })
        serviceGroup
        serviceName
        servicePort
        serviceUser
        ;
      inherit (confLib.static) routerServer;
    in
    {
      imports = [
      ];
      config = {
        swarselsystems.enabledServerModules = [ "mpd" ];
        sops.secrets.mpd-pw = {
          inherit sopsFile;
          group = serviceGroup;
          mode = "0440";
          owner = serviceUser;
        };
        users = {
          users = {
            ${serviceUser} = {
              extraGroups = [
                "audio"
                "utmp"
                "users"
                "pipewire"
              ];
              group = serviceGroup;
              isSystemUser = true;
            };
          };
          groups.mpd = { };
        };
        services.${serviceName} = {
          enable = true;
          credentials = [
            {
              passwordFile = config.sops.secrets.mpd-pw.path;
              permissions = [
                "read"
                "add"
                "control"
                "admin"
              ];
            }
          ];
          group = serviceGroup;
          openFirewall = true;
          settings = {
            audio_output = [
              {
                name = "PipeWire";
                type = "pipewire";
              }
            ];
            bind_to_address = "any";
            music_directory = "/storage/Music";
            port = servicePort;
          };
          user = serviceUser;
        };
        environment = {
          # topology.self.services.${serviceName} = {
          #   info = "http://localhost:${builtins.toString servicePort}";
          #   icon = lib.mkForce (sw.root "files/topology-images/mpd.png");
          # };
          persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
            directories = [
              {
                directory = "/var/lib/${serviceName}";
                group = "mpd";
                user = "mpd";
              }
            ];
          };
          systemPackages = with pkgs; [
            pciutils
            alsa-utils
            mpv
          ];
        };
        nodes.${routerServer}.networking.nftables.firewall.rules."fritzbox-to-${serviceName}" = {
          extraLines = [
            "ip saddr 192.168.178.0/24 tcp dport ${toString servicePort} accept"
          ];
          from = [ "untrusted" ];
          to = [ "vlan-services" ];
        };
      };

    }

  ) // { includes = [ ren.aspects.server-pipewire ]; };
}

# hintbooth-nginx: old hosts/nixos/x86_64-linux/hintbooth/guests/nginx/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.guest.hintbooth-nginx = {
    isImpermanence = true;
    nodeRoles = [ "homeWebProxy" ];
  };
  ren.aspects.hintbooth-nginx.at = ren.guest.hintbooth-nginx;
  ren.aspects.hintbooth-nginx.includes = [
    ren.aspects.acme
    ren.aspects.microvm-guest-shares
    ren.aspects.nginx
    ren.aspects.nginx-exporter
    ren.aspects.nginx-otel
    ren.aspects.oauth2-proxy
    ren.aspects.profile-microvm
  ];
  ren.aspects.hintbooth-nginx.nixos =
    {
      variant,
      globals-defs,
      host,
      config,
      lib,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
      confLib = sw.confLibOf { inherit host globals config; };
      inherit (confLib.static) nginxAccessRules;
    in
    {
      imports = [
      ];

      swarselsystems = {
        isMicroVM = true;
      };

    }
    // lib.optionalAttrs (!variant.minimal) {

      services.nginx = {
        upstreams.fritzbox = {
          servers.${globals.networks.home-lan.hosts.fritzbox.ipv4} = { };
        };
        virtualHosts.${globals.services.fritzbox.domain} = {
          acmeRoot = null;
          extraConfig = ''
            proxy_ssl_verify off;
          ''
          + nginxAccessRules;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://fritzbox";
            proxyWebsockets = true;
          };
          useACMEHost = globals.domains.main;
        };
      };
      microvm = {
        mem = 3072 * 1;
        vcpu = 1;
      };

    };
}

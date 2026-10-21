# vacanthouse sandbox services: old hosts/utility/vacanthouse/sandbox.nix
{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.vacanthouse-sandbox.includes = [ ren.aspects.homebox ];
  ren.aspects.vacanthouse-sandbox.nixos =
    {
      globals-defs,
      lib,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
    in
    {
      imports = [
      ];

      config = {
        sops.secrets.kanidm-homebox = {
          group = lib.mkForce "kanidm";
          mode = lib.mkForce "0440";
          owner = lib.mkForce "kanidm";
        };
        services.kanidm.provision.groups."homebox.access".members = [ "sandbox" ];
        networking.firewall.allowedTCPPorts = [ 7745 ];
        sandbox.tlsDomains = [ globals.services.homebox.domain ];
        virtualisation.vmVariant.virtualisation.forwardPorts = [
          {
            from = "host";
            guest.port = 7745;
            host.port = 7745;
          }
        ];
        systemd.services.homebox = {
          after = [
            "kanidm.service"
            "nginx.service"
          ];
          wants = [ "kanidm.service" ];
        };
      };
    };
}

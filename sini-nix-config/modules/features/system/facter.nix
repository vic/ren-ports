{ inputs, ... }:
{
  ren.aspects.system-facter.nixos =
    { host, ... }:
    {
      imports = [ inputs.nixos-facter-modules.nixosModules.facter ];
      facter = {
        reportPath = host.facts;
        detected = {
          dhcp.enable = false;
          graphics.enable = false;
        };
      };
    };
}

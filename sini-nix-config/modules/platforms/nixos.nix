# nixos class: metal hosts build nixosConfigurations (+ colmena-nodes, Q4); guests forward into their host's microvm.vms.
{ ren, ... }:
let
  inherit (ren.lib) and not;
in
{
  ren.aspects.metal.at = and [
    ren.kinds.host
    (not ren.kinds.guest)
  ];

  ren.classes.nixos = [
    {
      at = ren.aspects.metal;
      into =
        { host, ... }:
        ms: {
          nixosConfigurations.${host.name} = host.channel.nixosSystem {
            system = host.system.name;
            modules = ms;
          };
          # fleet channel `colmena-nodes` builds colmenaHive (channels/deploy-am.nix); address/user/tags from helpers.deployment
          colmena-nodes.${host.name} = {
            imports = ms;
            deployment = ren.helpers.deployment host;
            system = host.system.name;
            channel = host.channel.name;
            darwin = false;
          };
        };
    }
    {
      at = ren.kinds.guest;
      into =
        { guest, ... }:
        ms: {
          nixos.microvm.vms.${guest.name} = {
            pkgs = guest.microvm.guestPkgs; # null: microvm instantiates nixpkgs from the guest config
            nixpkgs = guest.channel.nixpkgs;
            config.imports = ms;
          };
        };
    }
    # user-scope nixos content forwards up to its host or guest
    {
      at = and [
        ren.kinds.user
        (ren.lib.within ren.kinds.host)
      ];
      into = _: ms: { nixos.imports = ms; };
    }
  ];
}

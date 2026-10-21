# profile-base: every machine. Old generic config-lib, vars, globals and nixos dns are helpers now (helpers/);
# old nixos `nodes` is the `nodes` aspect (topology/distributed.nix).
{ ren, ... }:
{
  ren.aspects.profile-base = {
    at = ren.kinds.machine;
    includes = [
      ren.aspects.meta
      ren.aspects.options
      ren.aspects.nftables
      ren.aspects.topology
      ren.aspects.id
      ren.aspects.sharedoptions
    ];
  };
}

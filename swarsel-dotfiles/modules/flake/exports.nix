# old flake/modules.nix: `nixosModules.default` and `homeModules` export profile-base for other flakes.
# WORKAROUND: Ren has no `ren.lib.moduleOf` yet (Ren README "use Ren aspects outside Ren: change needed").
# An `export` scope is a host that never builds: what lands on it (and on its user) becomes the exported module.
{ ren, ... }:
{
  ren.kinds.export = {
    is = ren.kinds.host; # host bindings (`host`, `globals-defs`) exist for the content
    below = [ ren.kinds.user ];
    spawns.user = s: ren.helpers.usersOf s.export;
  };
  ren.kinds.fleet.below = [ ren.kinds.export ];
  ren.kinds.fleet.spawns.export = s: if s.fleet.name == "swarsel" then ren.export else { };
  ren.export.base.system = ren.system.x86_64-linux;

  # only profile-base: machine identity and cross-node plumbing stay out of the export
  ren.aspects.export-base = {
    at = ren.kinds.export;
    excludes = [
      ren.aspects.host-facts
      ren.aspects.nodes
    ];
  };
}

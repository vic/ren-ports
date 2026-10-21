# Fleet: root of the scope tree. Environments, domains and systems hang below it.
{ ren, lib, ... }:
let
  inherit (ren.lib) opt;
  t = lib.types;
in
{
  ren.kinds.fleet = {
    below = [
      ren.kinds.environment
      ren.kinds.domain
      ren.kinds.system
    ];
    # a bare nested field group has no default (fleet.sini sets none): submodule with default {}
    secretsConfig = opt (t.submodule {
      options.masterIdentities = opt (t.listOf t.path) [
      ../../.secrets/pub/master.pub
      ../../.secrets/pub/master-clone1.pub
      ../../.secrets/pub/master-clone2.pub
      ];
    }) { };
  };
  ren.fleet.sini = { };
}

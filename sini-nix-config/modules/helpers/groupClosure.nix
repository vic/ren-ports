# groupClosure groups direct -> every group name `direct` reaches over group membership
# (den acl.nix transitiveGroups: member inherits the groups it is a member of).
# groups: attrset name -> group record (members = refs group). direct: list of group names.
{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
in
{
  ren.helpers.groupClosure =
    groups: direct:
    map (n: n.key) (
      lib.genericClosure {
        startSet = map (key: { inherit key; }) direct;
        operator =
          { key }:
          map (key: { inherit key; }) (
            lib.attrNames (lib.filterAttrs (_: g: lib.elem key (map (m: m.name) g.members)) groups)
          );
      }
    );
}

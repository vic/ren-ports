# Groups (data kind): ACL groups; members are groups whose members inherit this one.
{ ren, lib, ... }:
let
  inherit (ren.lib) opt;
  t = lib.types;
in
{
  ren.kinds.group = {
    labels = opt (t.listOf (t.enum [ "posix" "oauth-grant" "user-role" ])) [ ];
    description = opt t.str "";
    members = opt (t.listOf ren.kinds.group) [ ];
  };
}

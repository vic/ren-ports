{ ren, ... }:
{
  # each role names the node that fulfills it: `globals.general.<role> = <node name>`
  ren.aspects.node-roles.globals-defs =
    { host, ... }:
    {
      general = builtins.listToAttrs (
        map (name: {
          inherit name;
          value = host.name;
        }) host.nodeRoles
      );
    };
}

# darwin class: mac machines build darwinConfigurations (+ colmena-nodes; hive built in channels/deploy-am.nix).
{ ren, ... }:
{
  ren.classes.darwin = [
    {
      at = ren.kinds.mac;
    into =
      { mac, ... }:
      ms: {
        darwinConfigurations.${mac.name} = mac.channel.darwinSystem {
          system = mac.system.name;
          modules = ms;
        };
        colmena-nodes.${mac.name} = {
          imports = ms;
          deployment = ren.helpers.deployment mac;
          system = mac.system.name;
          channel = mac.channel.name;
          darwin = true;
        };
      };
    }
    # user-scope darwin content forwards up to its mac
    {
      at = ren.lib.and [
        ren.kinds.user
        (ren.lib.within ren.kinds.mac)
      ];
      into = _: ms: { darwin.imports = ms; };
    }
  ];
}

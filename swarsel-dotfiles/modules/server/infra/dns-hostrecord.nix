{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.dns-hostrecord.nixos =
    {
      globals-defs,
      host,
      config,
      lib,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
      confLib = sw.confLibOf { inherit host globals config; };
      inherit
        (confLib.gen {
          name = "dns-hostrecord";
          proxy = config.node.name;
        })
        proxyAddress4
        proxyAddress6
        ;
    in
    {
      config = lib.mkIf config.swarselsystems.isCloud {
        swarselsystems.enabledServerModules = [ "dns-hostrecord" ];
        globals.dns.${globals.domains.main}.subdomainRecords = {
          "server.${config.node.name}" = inputs.dns.lib.combinators.host proxyAddress4 proxyAddress6;
        };

      };
    }

  ;
}

{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.hexchat.homeManager =
    {
      globals-defs,
      config,
      osConfig ? null,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
      confLib = sw.confLibOf { host = null; inherit globals config; inherit osConfig; };
      moduleName = "hexchat";
      inherit (confLib.getConfig.repo.secrets.common.irc) irc_nick1;
    in
    {
      config = {
        swarselsystems.enabledHomeModules = [ "hexchat" ];
        programs.${moduleName} = {
          enable = true;
          settings = {
            inherit irc_nick1;
          };
        };
      };
    };
}

{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.attic-client.homeManager =
    {
      globals-defs,
      osConfig ? null,
      config,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
      confLib = sw.confLibOf { host = null; inherit globals config; inherit osConfig; };
      inherit (config.swarselsystems) mainUser;
    in
    {
      config = {
        swarselsystems = {
          enabledHomeModules = [ "attic-client" ];
          homeSopsSecrets.attic-cache-key = { };
        };
        programs.attic-client = {
          enable = true;
          settings = {
            default-server = mainUser;
            servers.${mainUser} = {
              endpoint = "https://${globals.services.attic.domain}";
              token-file = confLib.getConfig.sops.secrets.attic-cache-key.path;
            };
          };
          watchStore = [ "${mainUser}:${mainUser}" ];
        };
        systemd.user.services.attic-config.Unit.After = [ "sops-nix.service" ];
      };
    };
}
